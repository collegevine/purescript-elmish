module Elmish.Dispatch
    ( DispatchMsgFn(..)
    , DispatchMsg
    , DispatchError
    , dispatchMsgFn
    , issueError
    , issueMsg
    , ignoreMsg
    , cmapMaybe
    , handle
    , handleMaybe
    , class MkEventHandler
    , mkEventHandler
    , module Contravariant
    ) where

import Prelude

import Data.Bifunctor (rmap)
import Data.Either (Either(..), either)
import Data.Functor.Contravariant ((>$<), (>#<)) as Contravariant
import Data.Functor.Contravariant (class Contravariant)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Elmish.JsCallback (class MkJsCallback, JsCallback, jsCallback')

-- TODO: legacy placeholder. Remove.
type DispatchMsg = Effect Unit

-- | Represents a function that a view can use to report both errors and
-- | messages originating from JS/DOM. Underneath it's just a function that
-- | takes an `Either`, but it is wrapped in a newtype in order to provide class
-- | instances for it.
newtype DispatchMsgFn msg = DispatchMsgFn (Either DispatchError msg -> Effect Unit)

instance contravariantDispatch :: Contravariant DispatchMsgFn where
    cmap f (DispatchMsgFn dispatch) = DispatchMsgFn $ dispatch <<< rmap f

-- | Construct a `DispatchMsgFn` out of "on error" and "on message" handlers
dispatchMsgFn :: forall msg. (DispatchError -> Effect Unit) -> (msg -> Effect Unit) -> DispatchMsgFn msg
dispatchMsgFn onErr onMsg = DispatchMsgFn $ either onErr onMsg

-- | Report an error via the given dispatch function
issueError :: forall msg. DispatchMsgFn msg -> DispatchError -> Effect Unit
issueError (DispatchMsgFn d) = d <<< Left

-- | Issue a message via the given dispatch function
issueMsg :: forall msg. DispatchMsgFn msg -> msg -> Effect Unit
issueMsg (DispatchMsgFn d) = d <<< Right

-- | Creates a new `DispatchMsgFn` that relays errors from the given
-- | `DispatchMsgFn`, but throws away messages
ignoreMsg :: forall msg1 msg2. DispatchMsgFn msg1 -> DispatchMsgFn msg2
ignoreMsg = cmapMaybe $ const Nothing

-- | Allows to optionally convert the message to another type, swallowing the
-- | message when conversion fails.
cmapMaybe :: forall msg1 msg2
     . (msg2 -> Maybe msg1)
    -> DispatchMsgFn msg1
    -> DispatchMsgFn msg2
cmapMaybe f (DispatchMsgFn d) =
    DispatchMsgFn \msg2 -> case f <$> msg2 of
        Left err -> d $ Left err
        Right (Just msg1) -> d $ Right msg1
        Right Nothing -> pure unit

-- TODO: refine this
type DispatchError = String

-- | Creates a `JsCallback` that uses the given `DispatchMsgFn` to either issue
-- | a message or report an error. The `fn` parameter is either a message or a
-- | function that produces a message. When the JS code calls the resulting
-- | `JsCallback`, its parameters are validated, then the `fn` function is
-- | called to produce a message, which is then reported via the given
-- | `DispatchMsgFn`, unless the parameters passed from JS cannot be decoded, in
-- | which case an error is reported via `DispatchMsgFn`.
-- |
-- | Example of intended usage:
-- |
-- |      -- PureScript
-- |      data Message = A | B Int | C String Boolean
-- |
-- |      view state dispatch = createElement' viewCtor_
-- |          { foo: "bar"
-- |          , onA: handle dispatch A
-- |          , onB: handle dispatch B
-- |          , onC: handle dispatch C
-- |          , onBaz: handle dispatch \x y -> B (x+y)
-- |          }
-- |
-- |      // JSX:
-- |      export const viewCtor_ = args =>
-- |          <div>
-- |              Foo is {args.bar}<br />
-- |              <button onClick={args.onA}>A</button>
-- |              <button onClick={() => args.onB(42)}>B</button>
-- |              <button onClick={() => args.onC("hello", true)}>C</button>
-- |              <button onClick={() => args.onBaz(21, 21)}>Baz</button>
-- |          </div>
-- |
handle :: forall msg fn effFn
     . MkEventHandler msg fn effFn
    => MkJsCallback effFn
    => DispatchMsgFn msg
    -> fn
    -> JsCallback effFn
handle (DispatchMsgFn dispatch) fn =
    jsCallback' (mkEventHandler fn onMessage) onError
    where
        onMessage = dispatch <<< Right
        onError = dispatch <<< Left <<< show

-- | A version of `handle` (see comments there) with a possibility of not
-- | producing a message.
handleMaybe :: forall msg fn effFn
     . MkEventHandler (Maybe msg) fn effFn
    => MkJsCallback effFn
    => DispatchMsgFn msg
    -> fn
    -> JsCallback effFn
handleMaybe d = handle $ cmapMaybe identity d


-- | This type class and its instances are implementation of `handle` and
-- | `handleMaybe`. The base case is when `fn ~ msg` - that is when the
-- | message-producing function is not a function at all, but the message
-- | itself. The recursive instance prepends an argument `a`, thus allowing for
-- | curried functions with arbitrary number of parameters.
class MkEventHandler msg fn effFn | fn -> effFn, effFn -> fn where
    mkEventHandler ::
        fn                          -- ^ Either a message or a function that produces a message.
        -> (msg -> Effect Unit)     -- ^ The effect that is to be performed when this handler is invoked.
        -> effFn                    -- ^ An effectful function suitable for `mkJsCallback`

instance eventHandlerParameter :: MkEventHandler msg fn0 effFn0 => MkEventHandler msg (a -> fn0) (a -> effFn0) where
    mkEventHandler f dispatch a = mkEventHandler (f a) dispatch

else instance eventHandlerParameterless :: MkEventHandler msg msg (Effect Unit) where
    mkEventHandler msg dispatch = dispatch msg
