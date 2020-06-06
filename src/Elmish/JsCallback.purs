module Elmish.JsCallback
    ( JsCallback
    , JsCallback0
    , JsCallbackError
    , class MkJsCallback
    , jsCallback
    , jsCallback'
    , mkJsCallback
    , jsCallback0
    ) where

import Prelude

import Data.Array as Array
import Data.Either (Either(..), either)
import Data.Maybe (Maybe(..))
import Data.String (joinWith)
import Effect (Effect)
import Effect.Console as Console
import Elmish.Foreign (class CanPassToJavaScript, class CanReceiveFromJavaScript, Arguments, Foreign, argumentsToArray_, getArgument, mkVarArgEff_, readForeign, showForeign)

-- | This type represents a function that has been wrapped in a way suitable for
-- | passing to JavaScript (including parameter validation). The primary use
-- | case for such callbacks is to pass them to JSX code for receiving
-- | DOM-generated events and turning them into UI messages. See `MkJsCallback`
-- | for more info and examples.
newtype JsCallback fn = JsCallback Foreign
instance jsCbToJs :: MkJsCallback fn => CanPassToJavaScript (JsCallback fn)

-- | A parameterless `JsCallback`
type JsCallback0 = JsCallback (Effect Unit)

-- | Represents an error that may occur as a result of JS code calling a
-- | functuion wrapped as `JsCallback`.
data JsCallbackError
    = InvalidParameter { args :: Array Foreign, index :: Int }
    | InsufficientParameters { args :: Array Foreign, expected :: Int }

instance showJsCbError :: Show JsCallbackError where
    show err = case err of
        InvalidParameter e ->
            "Parameter #" <> show e.index <> " is malformed in " <> showArgs e.args
        InsufficientParameters e ->
            "Expected at least " <> show e.expected <> " parameters, but got " <> show (Array.length e.args) <> ": " <> showArgs e.args
        where
            showArgs args = "\nParameters: " <> "( " <> joinWith ", " (showForeign <$> args) <> " )"

-- | Deprecated. Same as `jsCallback`.
jsCallback0 :: Effect Unit -> JsCallback0
jsCallback0 fn = jsCallback fn

-- | Wraps a given effect `fn` (possibly with parameters) as a JS non-curried
-- | function with parameter type validation, making it suitable for passing to
-- | unsafe JS code.
-- |
-- | This function should not (or at least rarely) be used directly. In normal
-- | scenarios, `Elmish.Dispatch.handle` should be used instead.
-- |
-- | Example:
-- |
-- |       -- PureScript:
-- |       createElement' theView_
-- |           { onSave: jsCallback $ Console.log "Save"
-- |           , onCancel: jsCallback $ Console.log "Cancel"
-- |           , onFoo: jsCallback \(bar::String) (baz::Int) ->
-- |               Console.log $ "bar = " <> bar <> ", baz = " <> show baz
-- |           }
-- |
-- |      // JSX:
-- |      export const TheView = props =>
-- |        <div>
-- |          <button onClick={props.onSave}>Save</button>
-- |          <button onClick={props.onCancel}>Cancel</button>
-- |          <button onClick={() => props.onFoo("bar", 42)}>Foo</button>
-- |        </div>
-- |
-- | In this example, the parameters `bar` and `baz` will undergo validation at
-- | runtime to make sure they are indeed a `String` and an `Int` respectively,
-- | and an error will be issued if validation fails.
-- |
jsCallback :: forall fn.
    MkJsCallback fn
    => fn -- ^ the callback function, curried
    -> JsCallback fn
jsCallback k = jsCallback' k (Console.error <<< show)

-- | A more elaborate version of `jsCallback`, which takes an extra parameter
-- | - an effect to be performed in case of errors.
jsCallback' :: forall fn.
    MkJsCallback fn
    => fn                                  -- ^ the callback function, curried
    -> (JsCallbackError -> Effect Unit)    -- ^ error continuation
    -> JsCallback fn
jsCallback' k onError =
    JsCallback $ mkVarArgEff_ (either onError identity <<< mkJsCallback k 0)

-- | The core logic of jsCallback.
-- |
-- | This type class has two instances below:
-- |   * The instance `fn` ~ `Effect Unit` represents a parameterless callback.
-- |   * The instance `fn` ~ `MkJsCallback b => a -> b` is recursive, so it
-- |     represents a callback with one or more parameters.
class MkJsCallback fn where
    -- | This is the internal implementation of `jsCallback` and `jsCallback'`.
    -- | Do not use directly.
    mkJsCallback :: fn -> Int -> ParseM (Effect Unit)

instance jsCallbackEffect :: MkJsCallback (Effect Unit) where
    mkJsCallback f _ _ = pure f

instance jsCallbackFunction ::
    (CanReceiveFromJavaScript a, MkJsCallback b)
    => MkJsCallback (a -> b)
  where
    mkJsCallback f i args = do
        a <- readArg i args
        mkJsCallback (f a) (i+1) args

type ParseM a = Arguments -> Either JsCallbackError a

-- Internal implementation detail: validates type of an argument at given index,
-- return error if validation fails.
readArg :: forall a. CanReceiveFromJavaScript a => Int -> ParseM a
readArg i args =
    case getArgument args i of
        Nothing -> Left $ InsufficientParameters { args: argumentsToArray_ args, expected: i+1 }
        Just jsV -> case readForeign jsV of
            Nothing -> Left $ InvalidParameter { args: argumentsToArray_ args, index: i }
            Just a -> pure a
