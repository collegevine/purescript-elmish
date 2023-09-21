module Test.Component (spec) where

import Prelude

import Effect.Aff.AVar as AVar
import Effect.Aff.Class (class MonadAff, liftAff)
import Effect.Class (liftEffect)
import Effect.Ref as Ref
import Elmish (ComponentDef, forks, (<|))
import Elmish.Component (ComponentName(..), wrapWithLocalState)
import Elmish.HTML.Styled as H
import Elmish.Test (clickOn, find, nearestEnclosingReactComponentName, testComponent, text, waitUntil, (>>))
import Test.Examples.Counter as Counter
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (fail, shouldEqual)

spec :: Spec Unit
spec = describe "Elmish.Component" do
  it "can mount and drive a basic component" do
    testComponent (Counter.def { initialCount: 0 }) do
      find "p" >> text >>= shouldEqual "The count is: 0"
      clickOn "button.t--inc"
      find "p" >> text >>= shouldEqual "The count is: 1"
      clickOn "button.t--inc"
      find "p" >> text >>= shouldEqual "The count is: 2"
      clickOn "button.t--dec"
      find "p" >> text >>= shouldEqual "The count is: 1"

  it "names the root component ElmishRoot" $
    testComponent (Counter.def { initialCount: 0 }) $
      find "div" >> nearestEnclosingReactComponentName >>= shouldEqual "ElmishRoot"

  it "closes out subscriptions" do
    c <- subscribedComponent { def: Counter.def { initialCount: 0 }, onTrigger: Counter.Inc }

    testComponent (wrapperComponent c.def) do
      liftEffect (Ref.read c.alive) >>= shouldEqual false
      clickOn ".t--show"
      waitUntil $ liftEffect (Ref.read c.alive) <#> eq true
      find "p" >> text >>= shouldEqual "The count is: 0"
      liftAff $ AVar.put unit c.trigger
      waitUntil $ find "p" >> text <#> eq "The count is: 1"
      liftEffect (Ref.read c.alive) >>= shouldEqual true

      clickOn ".t--hide"
      waitUntil $ liftEffect (Ref.read c.alive) <#> eq false

      clickOn ".t--show"
      waitUntil $ liftEffect (Ref.read c.alive) <#> eq true

      clickOn ".t--hide"
      waitUntil $ liftEffect (Ref.read c.alive) <#> eq false

subscribedComponent :: ∀ m msg state. MonadAff m
  => { def :: ComponentDef msg state, onTrigger :: msg }
  -> m { alive :: Ref.Ref Boolean, trigger :: AVar.AVar Unit, def :: ComponentDef msg state }
subscribedComponent args = do
  alive <- liftEffect $ Ref.new false
  trigger <- liftAff AVar.empty

  let subscription = forks \{ dispatch, onStop } -> do
        liftEffect $ Ref.write true alive
        liftEffect $ onStop $ liftEffect $ Ref.write false alive
        void $ AVar.take trigger
        liftEffect (Ref.read alive) >>=
          if _
            then liftEffect (dispatch args.onTrigger)
            else fail "Triggered while not alive"

  pure
    { def: args.def { init = subscription *> args.def.init }
    , alive
    , trigger
    }

wrapperComponent :: ∀ msg state. ComponentDef msg state -> ComponentDef Boolean Boolean
wrapperComponent inner = { init: pure false, update, view }
  where
    update _ s = pure s

    view s dispatch = H.fragment
      [ H.button_ "t--show" { onClick: dispatch <| true } "Show"
      , H.button_ "t--hide" { onClick: dispatch <| false } "Hide"
      , if s
          then wrapWithLocalState (ComponentName "Inner") (const inner) unit
          else H.empty
      ]
