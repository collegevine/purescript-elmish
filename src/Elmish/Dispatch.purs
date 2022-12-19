module Elmish.Dispatch
  ( (<?|)
  , (<|)
  , Dispatch
  , class Handle
  , class HandleEffect
  , class HandleMaybe
  , handle
  , handleEffect
  , handleMaybe
  )
  where

import Prelude

import Data.Maybe (Maybe, maybe)
import Effect (Effect)
import Effect.Uncurried as E
import Safe.Coerce (coerce)
import Type.Equality (class TypeEquals)

-- | A function that a view can use to report messages originating from JS/DOM.
type Dispatch msg = msg -> Effect Unit

infixr 9 handle as <|
infixr 9 handleMaybe as <?|

class Handle msg event f where
    -- | A convenience function to make construction of event handlers with
    -- | arguments (i.e. `EffectFn1`) a bit shorter. The first parameter is a
    -- | `Dispatch`. The second parameter can be either a message or a function
    -- | from the event object to a message.
    -- |
    -- | Expected usage for this function is in its operator form `<|`
    -- |
    -- |     textarea
    -- |       { value: state.text
    -- |       , onChange: dispatch <| \e -> TextAreaChanged (E.textareaText e)
    -- |       , onMouseDown: dispatch <| TextareaClicked
    -- |       }
    -- |
    handle :: Dispatch msg -> f -> E.EffectFn1 event Unit

class HandleMaybe msg event f where
    -- | A variant of `handle` (aka `<|`) that allows to dispatch a message or
    -- | not conditionally via returning a `Maybe message`.
    -- |
    -- | Expected usage for this function is in its operator form `<?|`
    -- |
    -- |     div
    -- |       { onMouseDown: dispatch <?| \(E.MouseEvent e) ->
    -- |           if e.ctrlKey then Just ClickedWithControl else Nothing
    -- |       }
    -- |
    handleMaybe :: Dispatch msg -> f -> E.EffectFn1 event Unit

instance (TypeEquals msg output, TypeEquals event input) => Handle msg event (input -> output) where
    handle dispatch f = E.mkEffectFn1 $ dispatch <<< coerce <<< f <<< coerce
else instance TypeEquals msg output => Handle msg event output where
    handle dispatch msg = E.mkEffectFn1 \_ -> dispatch $ coerce msg

instance (TypeEquals msg output, TypeEquals event input) => HandleMaybe msg event (input -> Maybe output) where
    handleMaybe dispatch f = E.mkEffectFn1 $ maybe (pure unit) dispatch <<< coerce <<< f <<< coerce
else instance TypeEquals msg output => HandleMaybe msg event (Maybe output) where
    handleMaybe dispatch msg = E.mkEffectFn1 \_ -> maybe (pure unit) dispatch $ coerce msg

class HandleEffect event f where
    -- | An escape-hatch way to create an event handler for when neither
    -- | `handle` nor `handleMaybe` are appropriate, which usually happens when
    -- | the event handler must do something else, besides dispatching a
    -- | message.
    -- |
    -- | The argument may be either an `Effect Unit` or a function from the
    -- | event object to `Effect Unit`. If a message needs to be dispatched, the
    -- | consuming code is expected to do it via calling the `Dispatch` function
    -- | directly.
    -- |
    -- |     div
    -- |       { onKeyDown: E.handleEffect \(E.KeyboardEvent e) -> do
    -- |           window >>= localStorage >>= setItem "Last key pressed" e.key
    -- |           dispatch PressedKey
    -- |       , onClick: E.handleEffect \e -> do
    -- |           E.stopPropagation e
    -- |           dispatch ClickedDiv
    -- |       }
    handleEffect :: f -> E.EffectFn1 event Unit
instance TypeEquals event input => HandleEffect event (input -> Effect Unit) where
    handleEffect f = E.mkEffectFn1 $ f <<< coerce
else instance HandleEffect event (Effect Unit) where
    handleEffect = E.mkEffectFn1 <<< const
