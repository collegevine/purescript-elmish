module Elmish.Dispatch
  ( Dispatch
  , EventHandler
  , handle
  ) where

import Prelude

import Effect (Effect)
import Effect.Uncurried (EffectFn1, mkEffectFn1)
import Elmish.Foreign (class CanPassToJavaScript)

-- | A function that a view can use to report messages originating from JS/DOM.
type Dispatch msg = msg -> Effect Unit

-- | Type of event handling functions. This is the standard shape of all event
-- | handlers on React's built-in components (aka tags) and most third-party
-- | components as well. The constructor is intentionally hidden. Use the
-- | `handle` function to create instances of this type.
newtype EventHandler event = EventHandler (EffectFn1 event Unit)
instance CanPassToJavaScript (EventHandler event)

-- | Create a React event handler from a function `event -> Effect Unit`.
handle :: forall event. Dispatch event -> EventHandler event
handle dispatch = EventHandler $ mkEffectFn1 dispatch
