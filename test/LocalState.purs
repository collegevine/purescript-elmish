module Test.LocalState (spec) where

import Prelude

import Elmish.Component (ComponentName(..), wrapWithLocalState)
import Elmish.Enzyme (clickOn, exists, find, testComponent, text, (>>))
import Elmish.HTML.Styled as H
import Test.Examples.Counter as Counter
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)

spec :: Spec Unit
spec = describe "Elmish.Component.wrapWithLocalState" do

  it "maintains local event loop" do
    testComponent wrapperDef do
      find ".t--wrapper-1 p" >> text >>= shouldEqual "The count is: 42"
      clickOn "button.t--inc"
      find ".t--wrapper-1 p" >> text >>= shouldEqual "The count is: 43"
      exists ".t--wrapper-2 p" >>= shouldEqual false

  it "resets local state when the component is moved" do
    testComponent wrapperDef do
      find ".t--wrapper-1 p" >> text >>= shouldEqual "The count is: 42"
      exists ".t--wrapper-2 p" >>= shouldEqual false
      clickOn "button.t--inc"
      clickOn "button.t--inc"
      find ".t--wrapper-1 p" >> text >>= shouldEqual "The count is: 44"

      clickOn "button.t--toggle-both"

      -- wrapper-2 contains a whole new Counter (as far as React is concerned),
      -- unrelated to the one in wrapper-1, so it gets a brand new state of 42.
      find ".t--wrapper-2 p" >> text >>= shouldEqual "The count is: 42"
      exists ".t--wrapper-1 p" >>= shouldEqual false

  it "does not reset local state when props/args change" do
    testComponent wrapperDef do
      find ".t--wrapper-1 p" >> text >>= shouldEqual "The count is: 42"
      clickOn "button.t--inc-initial-count"

      -- The counter in wrapper-1 was already initialized by the time
      -- initialCount got incremented, so the new value of initialCount
      -- shouldn't affect wrapper-1's state.
      find ".t--wrapper-1 p" >> text >>= shouldEqual "The count is: 42"

      clickOn "button.t--toggle-second"

      -- But the counter in wrapper-2 gets initialized _after_ initialCount
      -- became 43, so that's what wrapper-2's state should become.
      find ".t--wrapper-2 p" >> text >>= shouldEqual "The count is: 43"

  where
    wrappedCounter =
      wrapWithLocalState (ComponentName "Counter") \c ->
        Counter.def { initialCount: c }

    wrapperDef = { init, view, update }
      where
        init = pure { initialCount: 42, showFirst: true, showSecond: false }

        view state dispatch =
          H.fragment
          [ H.div "t--wrapper-1" $
              if state.showFirst then wrappedCounter state.initialCount else H.empty
          , H.div "t--wrapper-2" $
              if state.showSecond then wrappedCounter state.initialCount else H.empty
          , H.button_ "t--toggle-first" { onClick: dispatch "ToggleFirst" } "."
          , H.button_ "t--toggle-second" { onClick: dispatch "ToggleSecond" } "."
          , H.button_ "t--toggle-both" { onClick: dispatch "ToggleBoth" } "."
          , H.button_ "t--inc-initial-count" { onClick: dispatch "IncInitialCount" } "."
          ]

        update state = case _ of
          "ToggleFirst" -> pure state { showFirst = not state.showFirst }
          "ToggleSecond" -> pure state { showSecond = not state.showSecond }
          "ToggleBoth" -> pure state { showFirst = not state.showFirst, showSecond = not state.showSecond }
          "IncInitialCount" -> pure state { initialCount = state.initialCount + 1 }
          _ -> pure state

