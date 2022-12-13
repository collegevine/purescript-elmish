module Elmish.Dispatch
  ( (<|)
  , Dispatch
  , class Handle
  , class HandleEffect
  , handle
  , handleEffect
  )
  where

import Prelude

import Data.Maybe (Maybe, maybe)
import Effect (Effect)
import Effect.Uncurried as E

-- | A function that a view can use to report messages originating from JS/DOM.
type Dispatch msg = msg -> Effect Unit

infixr 9 handle as <|

class Handle msg event f where
    -- | A convenience function to make construction of event handlers with
    -- | arguments (i.e. `EffectFn1`) a bit shorter. The function takes a `Dispatch`
    -- | and a mapping from the event argument to a message which the given
    -- | `Dispatch` accepts, and it's also available in operator form.
    -- |
    -- | The following example demonstrates expected usage of `handle` (in its
    -- | operator form `<|`):
    -- |
    -- |     textarea
    -- |       { value: state.text
    -- |       , onChange: dispatch <| E.inputText
    -- |       , onMouseDown: dispatch <| TextareaClicked
    -- |       }
    -- |
    handle :: Dispatch msg -> f -> E.EffectFn1 event Unit

instance Handle msg event (event -> Maybe msg) where
    handle dispatch f = E.mkEffectFn1 $ maybe (pure unit) dispatch <<< f
else instance Handle msg event (event -> msg) where
    handle dispatch f = E.mkEffectFn1 $ dispatch <<< f
else instance Handle msg event (event -> Effect (Maybe msg)) where
    handle dispatch f = E.mkEffectFn1 $ maybe (pure unit) dispatch <=< f
else instance Handle msg event (event -> Effect msg) where
    handle dispatch f = E.mkEffectFn1 $ dispatch <=< f
else instance Handle msg event (Effect msg) where
    handle dispatch msg = E.mkEffectFn1 \_ -> dispatch =<< msg
else instance Handle msg event msg where
    handle dispatch msg = E.mkEffectFn1 \_ -> dispatch msg

class HandleEffect event f where
    handleEffect :: f -> E.EffectFn1 event Unit

instance HandleEffect event (event -> Effect Unit) where
    handleEffect f = E.mkEffectFn1 f
else instance HandleEffect event (Effect Unit) where
    handleEffect f = E.mkEffectFn1 $ const f
