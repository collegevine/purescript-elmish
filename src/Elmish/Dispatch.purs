module Elmish.Dispatch
  ( (<!|)
  , (<?|)
  , (<|)
  , Dispatch
  , class SpecializedEvent, specializeEvent
  , class SpecializedEvent', specializeEvent'
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
infixr 9 handleEffect as <!|

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

class SpecializedEvent' raw specialized where
    specializeEvent' :: raw -> specialized
instance SpecializedEvent' a a where specializeEvent' = identity
else instance SpecializedEvent a b => SpecializedEvent' a b where specializeEvent' = specializeEvent

handle :: forall msg raw specialized. SpecializedEvent' raw specialized => Dispatch msg -> (specialized -> msg) -> E.EffectFn1 raw Unit
handle dispatch f = E.mkEffectFn1 $ dispatch <<< f <<< specializeEvent'

handleMaybe :: forall msg raw specialized. SpecializedEvent' raw specialized => Dispatch msg -> (specialized -> Maybe msg) -> E.EffectFn1 raw Unit
handleMaybe dispatch f = E.mkEffectFn1 $ maybe (pure unit) dispatch <<< f <<< specializeEvent'

handleEffect :: forall raw specialized. SpecializedEvent' raw specialized => (specialized -> Effect Unit) -> E.EffectFn1 raw Unit
handleEffect f = E.mkEffectFn1 \e -> f $ specializeEvent' e
