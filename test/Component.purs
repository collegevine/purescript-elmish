module Test.Component (spec) where

import Prelude

import Elmish.Test (clickOn, find, nearestEnclosingReactComponentName, testComponent, text, (>>))
import Test.Examples.Counter as Counter
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
