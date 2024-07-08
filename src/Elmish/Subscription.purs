-- | A facade API for expressing the idea of "external events" - i.e. messages
-- | that do not originate in the UI itself, but come from other sources, such
-- | as network, browser URL history manipulations, timer, JS workers, and so
-- | on. The API in this module allows capturing such external events and
-- | converting them to Elmish messages, so they can be handled in the UI
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
module Elmish.Subscription
  ( Subscription(..)
  , hush
  , quasiBind
  , subscribe
  , subscribe'
  , subscribeMaybe
  )
  where

import Prelude

import Data.Maybe (Maybe, maybe)
import Effect.Aff (Aff, launchAff_)
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
subscribe f sub = sub <#> f # subscribe'

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
subscribeMaybe f sub = sub <#> f # hush # subscribe'

-- | A version of `subscribe` without the convenience mapping function. This
-- | function is to support the implementation of lower-level primitives. In
-- | most cases, in actual UI component code, `subscribe` should be used.
subscribe' :: ∀ m a. MonadEffect m => Subscription m a -> Transition' m a Unit
subscribe' (Subscription go) =
  forks \{ dispatch, onStop } -> do
    stop <- go dispatch
    liftEffect $ onStop stop

-- | This is almost a `bind`, but not quite. The continuation function, instead
-- | of returning another `Subscription` (as a well behaved `bind` would),
-- | returns an `Aff`. Another way of looking at it is as a version of `map`,
-- | but with the mapping function being effectful.
-- |
-- | This is useful for building more complicated subscriptions on top of
-- | simpler ones. One can imagine a subscription that listens to a websocket,
-- | and upon getting a signal, fetches some data from the server, and this data
-- | becomes the "output" value of the subscription.
-- |
-- | Q: Why not have a real `bind`?
-- |
-- | A: Since subscriptions are basically "infinite" streams of future values,
-- |    every incoming value from the outer subscription will have to create a
-- |    new subscription and keep it indefinitely, or until the outer
-- |    subscription is stopped. This means that the `bind` will have to have a
-- |    local store of all new subscriptions created by the continuation
-- |    function, so that it can stop all of them when the outer subscription is
-- |    stopped. And this is just a memory leak. To be sure, there are ways
-- |    around that (basically reinventing reactive programming), but this use
-- |    case does not require that level of complexity.
-- |
quasiBind :: ∀ m a b. (a -> Aff b) -> Subscription m a -> Subscription m b
quasiBind f (Subscription go) =
  Subscription \dispatch ->
    go \a -> launchAff_ do
      b <- f a
      liftEffect $ dispatch b

-- | Given a `Maybe`-producing subscription, creates a new subscription that
-- | filters out `Nothing` values and fires only on receiving `Just`.
hush :: ∀ m a. Subscription m (Maybe a) -> Subscription m a
hush (Subscription go) =
  Subscription \dispatch ->
    go $ maybe (pure unit) dispatch
