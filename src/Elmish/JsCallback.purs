module Elmish.JsCallback
    ( JsCallback
    , JsCallback0
    , JsCallbackError
    , class MkJsCallback
    , mkJsCallback
    , mkJsCallback'
    , jsCallback0
    ) where

import Prelude

import Data.Array as Array
import Data.Either (Either(..), either)
import Data.Maybe (Maybe(..))
import Data.String (joinWith)
import Effect (Effect)
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

-- | A wrapper for `mkJsCallback` (see comments there)
jsCallback0 :: Effect Unit -> JsCallback0
jsCallback0 fn = mkJsCallback fn ignoreErrors
    where
        -- Ignoring errors here is safe, because the only errors that can
        -- actually be produced by a `JsCallback` are parameter validation
        -- errors. Therefore, for a parameterless effect, there can be none.
        ignoreErrors _ = pure unit

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
-- |           { onSave: jsCallback0 $ Console.log "Save"
-- |           , onCancel: jsCallback0 $ Console.log "Cancel"
-- |           , onFoo: mkJsCallback
-- |                (\(bar::Int) (baz::Int) ->
-- |                     Console.log $ "bar = " <> show bar <> ", baz = " <> show baz
-- |                )
-- |                (\err -> pure unit {- ignore errors -})
-- |           }
-- |
-- |      // JSX:
-- |      export const TheView = props =>
-- |        <div>
-- |          <button onClick={props.onSave}>Save</button>
-- |          <button onClick={props.onCancel}>Cancel</button>
-- |          <button onClick={() => props.onFoo("bar", "baz")}>Foo</button>
-- |        </div>
-- |
-- | In this example, the parameters `bar` and `baz` will undergo validation at
-- | runtime, and an error will be issued if validation fails.
-- |
mkJsCallback :: forall fn.
    MkJsCallback fn
    => fn                                  -- ^ the callback function, curried
    -> (JsCallbackError -> Effect Unit)    -- ^ error continuation
    -> JsCallback fn
mkJsCallback k onError =
    JsCallback $ mkVarArgEff_ (either onError identity <<< mkJsCallback' k 0)

-- | The core logic of mkJsCallback.
-- |
-- | This type class has two instances below:
-- |   * The instance `fn` ~ `Effect Unit` represents a parameterless callback.
-- |   * The instance `fn` ~ `MkJsCallback b => a -> b` is recursive, so it
-- |     represents a callback with one or more parameters.
class MkJsCallback fn where
    mkJsCallback' :: fn -> Int -> ParseM (Effect Unit)

instance jsCallbackEffect :: MkJsCallback (Effect Unit) where
    mkJsCallback' f _ _ = pure f

instance jsCallbackFunction ::
    (CanReceiveFromJavaScript a, MkJsCallback b)
    => MkJsCallback (a -> b)
  where
    mkJsCallback' f i args = do
        a <- readArg i args
        mkJsCallback' (f a) (i+1) args

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
