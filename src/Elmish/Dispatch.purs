module Elmish.Dispatch
  ( (<|)
  , Dispatch
  , class SpecializedEvent, specializeEvent
  , class Handle, handle
  )
  where

import Prelude

import Data.Maybe (Maybe, maybe)
import Effect (Effect)
import Effect.Uncurried as E

-- | A function that a view can use to report messages originating from JS/DOM.
type Dispatch msg = msg -> Effect Unit

infixr 9 handle as <|
-- infixr 9 handleMaybe as <?|

-- | A convenience function to make construction of event handlers with
-- | arguments (i.e. `EffectFn1`) a bit shorter. The function takes a `Dispatch`
-- | and a mapping from the event argument to a message which the given
-- | `Dispatch` accepts, and it's also available in operator form.
-- |
-- | The following example demonstrates expected usage of both `handle` (in its
-- | operator form `<|`) and `handleMaybe` (in its operator form `<?|`):
-- |
-- |     textarea
-- |       { value: state.text
-- |       , onChange: dispatch <?| \e -> TextChanged <$> eventTargetValue e
-- |       , onMouseDown: dispatch <| \_ -> TextareaClicked
-- |       }
-- |
-- |       where
-- |         eventTargetValue = readForeign >=> lookup "target" >=> readForeign >=> lookup "value"
-- |

class SpecializedEvent raw specialized where
    specializeEvent :: raw -> specialized

class Handle msg raw f where
    handle :: Dispatch msg -> f -> E.EffectFn1 raw Unit

instance Handle msg raw (raw -> Maybe msg) where
    handle dispatch f = E.mkEffectFn1 $ maybe (pure unit) dispatch <<< f
else instance Handle msg raw (raw -> msg) where
    handle dispatch f = E.mkEffectFn1 $ dispatch <<< f
else instance SpecializedEvent raw specialized => Handle msg raw (specialized -> Maybe msg) where
    handle dispatch f = E.mkEffectFn1 $ maybe (pure unit) dispatch <<< f <<< specializeEvent
else instance SpecializedEvent raw specialized => Handle msg raw (specialized -> msg) where
    handle dispatch f = E.mkEffectFn1 $ dispatch <<< f <<< specializeEvent
else instance Handle msg raw (raw -> Effect (Maybe msg)) where
    handle dispatch f = E.mkEffectFn1 $ maybe (pure unit) dispatch <=< f
else instance Handle msg raw (raw -> Effect msg) where
    handle dispatch f = E.mkEffectFn1 $ dispatch <=< f
else instance SpecializedEvent raw specialized => Handle msg raw (specialized -> Effect (Maybe msg)) where
    handle dispatch f = E.mkEffectFn1 $ maybe (pure unit) dispatch <=< (f <<< specializeEvent)
else instance SpecializedEvent raw specialized => Handle msg raw (specialized -> Effect msg) where
    handle dispatch f = E.mkEffectFn1 $ dispatch <=< (f <<< specializeEvent)
else instance Handle msg raw (Effect msg) where
    handle dispatch msg = E.mkEffectFn1 \_ -> dispatch =<< msg
else instance Handle msg raw msg where
    handle dispatch msg = E.mkEffectFn1 \_ -> dispatch msg
