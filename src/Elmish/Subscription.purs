-- | A facade API for expressing the idea of "external events" - i.e. messages
-- | that do not originate in the UI itself, but come from other sources, such
-- | as network, browser URL history manipulations, timer, JS workers, and so
-- | on. The API in this module allows capturing such external events and
-- | convert them to Elmish messages, so they can be handled in the UI
-- | component's `update` function.
-- |
-- | A `Subscription` value represents such an "external event" packaged for
-- | reuse, while `subscribe` and `subscribeMaybe` functions allow to "start"
-- | such subscription by including it in a state transition - usually the
-- | initial one. When the component is destroyed (in React lingo -
-- | "unmounted"), all its subscriptions are terminated.
-- |
-- | Example:
-- |
-- |      -- A reusable library
-- |      module Location where
-- |
-- |      urlUpdates :: ∀ m. MonadEffect m => Subscription m { path :: String, query :: String }
-- |      urlUpdates = Subscription \dispatch -> do
-- |        listener <- eventListener \_ -> do
-- |          path <- window >>= location >>= pathname
-- |          query <- window >>= location >>= search
-- |          dispatch { path, query }
-- |
-- |        window <#> toEventTarget >>= addEventListener popstate listener false
-- |
-- |        pure $
-- |          window <#> toEventTarget >>= removeEventListener popstate listener false
-- |
-- |
-- |      -- Consuming code
-- |      type State = ...
-- |      data Message
-- |        = UrlChanged { path :: String, query :: String }
-- |        | ...
-- |
-- |      myComponent :: ComponentDef Message State
-- |      myComponent = { init, view, update }
-- |        where
-- |          init = do
-- |            subscribe UrlChanged Location.urlUpdates
-- |            ...
-- |
-- |          view = ...
-- |          update = ...
-- |
module Elmish.Subscriptions
  ( Subscription(..)
  , subscribe
  , subscribeMaybe
  )
  where

import Prelude

import Data.Maybe (Maybe(..), maybe)
import Effect.Class (class MonadEffect, liftEffect)
import Elmish.Component (Transition', forks)
import Elmish.Dispatch (Dispatch)

-- | Represents an external event, such as network, times, JS worker, etc.
-- |
-- | The value wrapped in the newtype is a function that takes a
-- | message-dispatching callback, through which the subscription can send
-- | messages, and returns a "cleanup" action, which will be executed when it's
-- | time to unsubscribe from the subscription.
newtype Subscription m a = Subscription (Dispatch a -> m (m Unit))
derive instance Functor (Subscription m)

-- | Given a subscription and a message constructor, this function "starts" the
-- | subscription by embedding it in a state transition, which is then intended
-- | to be part of a larger state transition - either a component's `update` or
-- | `init` function.
-- |
-- | Example:
-- |
-- |      data Message
-- |        = UrlChanged { path :: String, query :: String }
-- |        | ...
-- |
-- |      myComponent :: ComponentDef Message State
-- |      myComponent = { init, view, update }
-- |        where
-- |          init = do
-- |            subscribe UrlChanged Location.urlUpdates
-- |            ...
-- |
-- |          view = ...
-- |          update = ...
-- |
subscribe :: ∀ m a msg. MonadEffect m => (a -> msg) -> Subscription m a -> Transition' m msg Unit
subscribe f = subscribeMaybe (Just <<< f)

-- | Similar to `subscribe`, but instead of a message constructor, takes a
-- | function returning `Maybe Message` for issuing messages conditionally.
-- |
-- | Example:
-- |
-- |      data Message
-- |        = UrlChanged String
-- |        | ...
-- |
-- |      myComponent :: ComponentDef Message State
-- |      myComponent = { init, view, update }
-- |        where
-- |          init = do
-- |            Location.urlUpdates # subscribeMaybe \{ path } ->
-- |              if path == "boring" then Nothing else Just $ UrlChanged path
-- |            ...
-- |
-- |          view = ...
-- |          update = ...
-- |
subscribeMaybe :: ∀ m a msg. MonadEffect m => (a -> Maybe msg) -> Subscription m a -> Transition' m msg Unit
subscribeMaybe f (Subscription go) =
  forks \{ dispatch, onStop } -> do
    stop <- go $ f >>> maybe (pure unit) dispatch
    liftEffect $ onStop stop
