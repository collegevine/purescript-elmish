module Elmish.Dispatch
    ( Dispatch
    , handle
    , handleMaybe
    , (<|)
    , (<?|)
    , module E
    ) where

import Prelude

import Data.Maybe (Maybe, maybe)
import Effect (Effect)
import Effect.Uncurried (EffectFn1, EffectFn2, mkEffectFn1, mkEffectFn2) as E

-- | A function that a view can use to report messages originating from JS/DOM.
type Dispatch msg = msg -> Effect Unit

infixr 9 handle as <|
infixr 9 handleMaybe as <?|

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
handle :: forall arg msg. Dispatch msg -> (arg -> msg) -> E.EffectFn1 arg Unit
handle dispatch fn = E.mkEffectFn1 $ dispatch <<< fn

-- | Same as `handle`, but dispatches a message optionally. See comments on
-- | `handle` for an example.
handleMaybe :: forall arg msg. Dispatch msg -> (arg -> Maybe msg) -> E.EffectFn1 arg Unit
handleMaybe dispatch fn = E.mkEffectFn1 $ maybe (pure unit) dispatch <<< fn
