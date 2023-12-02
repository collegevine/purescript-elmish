module Test.Subscriptions (spec) where

import Prelude

import Effect.Aff (forkAff)
import Effect.Aff.AVar as AVar
import Effect.Aff.Class (class MonadAff, liftAff)
import Effect.Class (liftEffect)
import Effect.Ref as Ref
import Elmish (ComponentDef, Transition, forks)
import Elmish.Subscription (Subscription(..), subscribe)
import Elmish.Test (clickOn, find, testComponent, text, waitUntil, (>>))
import Test.Examples.Counter as Counter
import Test.Examples.WrapperComponent (wrapperComponent)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (fail, shouldEqual)

spec :: Spec Unit
spec = describe "Elmish.Component - subscriptions" do

  mkTestCase "directly via forks" subscriptionViaForks
  mkTestCase "via subscription API" subscriptionViaSubscriptionApi

  where
    mkTestCase name mkSubscription = describe name do
      it "single level" do
        c <- subscribedComponent mkSubscription $ Counter.def { initialCount: 0 }

        testComponent (wrapperComponent "" c.def) do
          liftEffect (Ref.read c.alive) >>= shouldEqual false
          clickOn ".t--show-child"
          waitUntil $ liftEffect (Ref.read c.alive) <#> eq true
          find "p" >> text >>= shouldEqual "The count is: 0"
          liftAff $ AVar.put Counter.Inc c.trigger
          waitUntil $ find "p" >> text <#> eq "The count is: 1"
          liftEffect (Ref.read c.alive) >>= shouldEqual true

          clickOn ".t--hide-child"
          waitUntil $ liftEffect (Ref.read c.alive) <#> eq false

          clickOn ".t--show-child"
          waitUntil $ liftEffect (Ref.read c.alive) <#> eq true

          clickOn ".t--hide-child"
          waitUntil $ liftEffect (Ref.read c.alive) <#> eq false

      it "doubly nested" do
        c <- subscribedComponent mkSubscription $ Counter.def { initialCount: 0 }
        let inner = wrapperComponent "t--inner" c.def
            outer = wrapperComponent "t--outer" inner

        testComponent outer do
          liftEffect (Ref.read c.alive) >>= shouldEqual false

          clickOn ".t--outer.t--show-child"
          liftEffect (Ref.read c.alive) >>= shouldEqual false

          clickOn ".t--inner.t--show-child"
          waitUntil $ liftEffect (Ref.read c.alive) <#> eq true

          -- Telling the 'outer' component to hide the 'inner' component, which
          -- should also trigger unmounting of the 'c' component inside the
          -- 'inner', thus ending the subscription.
          clickOn ".t--outer.t--hide-child"
          waitUntil $ liftEffect (Ref.read c.alive) <#> eq false

-- A helper component that wraps another component, but adds a subscription,
-- which (1) sets a boolean cell to true/false on subscribe/unsubscribe and (2)
-- waits for an AVar to pulse and when it does, issues a given message.
subscribedComponent :: ∀ m msg state. MonadAff m
  => ({ alive :: Ref.Ref Boolean, trigger :: AVar.AVar msg } -> Transition msg Unit)
  -> ComponentDef msg state
  -> m { alive :: Ref.Ref Boolean, trigger :: AVar.AVar msg, def :: ComponentDef msg state }
subscribedComponent mkSubscription wrappedDef = do
  alive <- liftEffect $ Ref.new false
  trigger <- liftAff AVar.empty

  let subscription = mkSubscription { alive, trigger }
      def = wrappedDef { init = subscription *> wrappedDef.init }

  pure { def, alive, trigger }

subscriptionViaForks :: ∀ msg. { alive :: Ref.Ref Boolean, trigger :: AVar.AVar msg } -> Transition msg Unit
subscriptionViaForks { alive, trigger } =
  forks \{ dispatch, onStop } -> do
    liftEffect $ Ref.write true alive
    liftEffect $ onStop $ liftEffect $ Ref.write false alive
    msg <- AVar.take trigger
    liftEffect (Ref.read alive) >>=
      if _
        then liftEffect (dispatch msg)
        else fail "Triggered while not alive"

subscriptionViaSubscriptionApi :: ∀ msg. { alive :: Ref.Ref Boolean, trigger :: AVar.AVar msg } -> Transition msg Unit
subscriptionViaSubscriptionApi { alive, trigger } =
  subscribe identity $ Subscription \dispatch -> do
    liftEffect $ Ref.write true alive
    void $ forkAff do
      msg <- AVar.take trigger
      liftEffect (Ref.read alive) >>=
        if _
          then liftEffect (dispatch msg)
          else fail "Triggered while not alive"

    pure $ liftEffect $ Ref.write false alive
