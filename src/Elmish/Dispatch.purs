module Elmish.Dispatch
  ( (<|)
  , (<!|)
  , Dispatch
  , class Handle
  , class HandleEffect
  , class SpecializedEvent
  , handle
  , handleEffect
  , handleStrict
  , specializeEvent
  )
  where

import Prelude

import Data.Maybe (Maybe, maybe)
import Effect (Effect)
import Effect.Uncurried as E

-- | A function that a view can use to report messages originating from JS/DOM.
type Dispatch msg = msg -> Effect Unit

infixr 9 handle as <|
infixr 9 handleStrict as <!|

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

class HandleEffect raw f where
    handleEffect :: f -> E.EffectFn1 raw Unit

instance HandleEffect raw (raw -> Effect Unit) where
    handleEffect f = E.mkEffectFn1 f
else instance SpecializedEvent raw specialized => HandleEffect raw (specialized -> Effect Unit) where
    handleEffect f = E.mkEffectFn1 $ f <<< specializeEvent
else instance HandleEffect raw (Effect Unit) where
    handleEffect f = E.mkEffectFn1 $ const f

handleStrict :: ∀ event msg. Dispatch msg -> (event -> msg) -> E.EffectFn1 event Unit
handleStrict dispatch f = E.mkEffectFn1 $ dispatch <<< f
