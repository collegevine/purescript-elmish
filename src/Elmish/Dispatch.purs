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

-- | A function that a view can use to report messages originating from JS/DOM.
type Dispatch msg = msg -> Effect Unit

infixr 9 handle as <|
infixr 9 handleMaybe as <?|

class Handle msg event f | f -> msg, f -> event where
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

class HandleMaybe msg event f | f -> msg, f -> event where
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

instance Handle msg event (event -> msg) where
    handle dispatch f = E.mkEffectFn1 $ dispatch <<< f
else instance Handle msg event msg where
    handle dispatch msg = E.mkEffectFn1 \_ -> dispatch msg

instance HandleMaybe msg event (event -> Maybe msg) where
    handleMaybe dispatch f = E.mkEffectFn1 $ maybe (pure unit) dispatch <<< f
else instance HandleMaybe msg event (Maybe msg) where
    handleMaybe dispatch msg = E.mkEffectFn1 \_ -> maybe (pure unit) dispatch msg

class HandleEffect event f | f -> event where
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
instance HandleEffect event (event -> Effect Unit) where
    handleEffect f = E.mkEffectFn1 f
else instance HandleEffect event (Effect Unit) where
    handleEffect = E.mkEffectFn1 <<< const
