module Test.Component (spec) where

import Prelude

import Effect.Aff (Milliseconds(..), delay)
import Effect.Aff.AVar as AVar
import Effect.Aff.Class (class MonadAff, liftAff)
import Effect.Class (liftEffect)
import Effect.Ref as Ref
import Elmish (forkVoid, forks)
import Elmish.HTML.Styled as H
import Elmish.Test (clickOn, find, nearestEnclosingReactComponentName, testComponent, text, (>>))
import Test.Examples.Counter as Counter
import Test.Examples.WrapperComponent (wrapperComponent)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)

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

  describe "does not issue new messages after unmounting" do
    it "for top-level component" do
      c <- effectfulComponent

      liftEffect (Ref.read c.componentMounted) >>= shouldEqual false

      testComponent c.def do
        liftAff $ delay $ Milliseconds 1.0
        liftEffect (Ref.read c.componentMounted) >>= shouldEqual true

        -- The component has mounted => kicking it should produce a message, which should increase the counter
        effectfulComponentTick c 1
        effectfulComponentTick c 2

      -- The component should have unmounted now => no more messages => no more counter increments
      effectfulComponentTick c 2
      effectfulComponentTick c 2

    it "for locally wrapped nested component" do
      c <- effectfulComponent

      testComponent (wrapperComponent "" c.def) do
        liftEffect (Ref.read c.componentMounted) >>= shouldEqual false

        clickOn ".t--show-child"
        liftAff $ delay $ Milliseconds 1.0
        liftEffect (Ref.read c.componentMounted) >>= shouldEqual true
        effectfulComponentTick c 1
        effectfulComponentTick c 2

        -- Hiding the locally-bound component unmounts it => no more messages => no more counter increments
        clickOn ".t--hide-child"
        effectfulComponentTick c 2
        effectfulComponentTick c 2

        -- Before instantiating the nested component a second time, stop the old
        -- instantiation's loop so it doesn't hog the AVar.
        liftAff $ AVar.put "stop" c.trigger

        clickOn ".t--show-child"
        liftAff $ delay $ Milliseconds 1.0
        effectfulComponentTick c 3
        effectfulComponentTick c 4

        clickOn ".t--hide-child"
        effectfulComponentTick c 4
        effectfulComponentTick c 4

  where
    effectfulComponent = do
      trigger <- liftAff AVar.empty
      triggered <- liftEffect $ Ref.new 0
      componentMounted <- liftEffect $ Ref.new false

      let
        loop args = do
          a <- liftAff $ AVar.take trigger
          unless (a == "stop") do
            liftEffect $ args.dispatch unit
            loop args

        init = do
          forkVoid $ liftEffect $ Ref.write true componentMounted
          forks loop

        update _ _ =
          forkVoid $ liftEffect $ Ref.modify_ (add 1) triggered

        view _ _ =
          H.empty

      pure { def: { init, update, view }, trigger, triggered, componentMounted }

    effectfulComponentTick :: ∀ m. MonadAff m => _ -> _ -> m Unit
    effectfulComponentTick component expectedTriggerCount = liftAff do
      AVar.put "" component.trigger
      delay $ Milliseconds 1.0
      liftEffect (Ref.read component.triggered) >>= shouldEqual expectedTriggerCount

