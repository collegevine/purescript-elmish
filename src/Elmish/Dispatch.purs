module Elmish.Dispatch
    ( Dispatch
    , handle
    , handleMaybe
    ) where

import Prelude

import Data.Maybe (Maybe, maybe)
import Effect (Effect)
import Effect.Uncurried (EffectFn1, mkEffectFn1)

-- | A function that a view can use to report messages originating from JS/DOM.
type Dispatch msg = msg -> Effect Unit

infixr 9 handle as <|
infixr 9 handleMaybe as <?|

handle :: forall arg msg. Dispatch msg -> (arg -> msg) -> EffectFn1 arg Unit
handle dispatch fn = mkEffectFn1 $ dispatch <<< fn

handleMaybe :: forall arg msg. Dispatch msg -> (arg -> Maybe msg) -> EffectFn1 arg Unit
handleMaybe dispatch fn = mkEffectFn1 $ maybe (pure unit) dispatch <<< fn
