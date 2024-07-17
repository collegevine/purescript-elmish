module Test.LocalState (spec) where

import Prelude

import Data.Array (length)
import Effect.Aff (Milliseconds(..), delay)
import Effect.Aff.Class (liftAff)
import Elmish (fork, (<|))
import Elmish.Component (ComponentName(..), wrapWithLocalState)
import Elmish.HTML.Styled as H
import Elmish.Test (clickOn, exists, find, findAll, forEach, nearestEnclosingReactComponentName, testComponent, text, (>>))
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

  it "names the React component according to the ComponentName passed in" $
    testComponent wrapperDef do
      find ".t--wrapper-1 div" >> nearestEnclosingReactComponentName >>= shouldEqual "Elmish_Counter"
      findAll ".t--counter" <#> length >>= shouldEqual 1
      findAll ".t--counter" >>= forEach (nearestEnclosingReactComponentName >>= shouldEqual "Elmish_Counter")
      clickOn ".t--toggle-second"
      findAll ".t--counter" <#> length >>= shouldEqual 2
      findAll ".t--counter" >>= forEach (nearestEnclosingReactComponentName >>= shouldEqual "Elmish_Counter")

  it "calls the correct closure of `update` when dispatching events" $
    testComponent closureOuter do
      find ".t--count" >> text >>= shouldEqual "0"
      find ".t--increment" >> text >>= shouldEqual "10"
      clickOn ".t--inc"
      find ".t--count" >> text >>= shouldEqual "10"
      find ".t--increment" >> text >>= shouldEqual "10"
      clickOn ".t--increase-increment"
      find ".t--count" >> text >>= shouldEqual "10"
      find ".t--increment" >> text >>= shouldEqual "11"
      clickOn ".t--long-inc"
      liftAff $ delay $ Milliseconds 20.0
      find ".t--count" >> text >>= shouldEqual "21"
      find ".t--increment" >> text >>= shouldEqual "11"

      -- We're going to initiate a "long inc" and while it's in flight, we're
      -- going to increase increment. If the closure that captured the previous
      -- value of `increment` survives until after the long inc is done, the
      -- resulting count will be incorrectly set at 21 + 11 = 32. If the old
      -- value of `increment` wasn't captured and the fresh value is used, the
      -- count will be 21 + 12 = 33.
      clickOn ".t--long-inc"
      liftAff $ delay $ Milliseconds 5.0
      clickOn ".t--increase-increment"
      find ".t--count" >> text >>= shouldEqual "21"
      find ".t--increment" >> text >>= shouldEqual "12"
      liftAff $ delay $ Milliseconds 15.0
      find ".t--count" >> text >>= shouldEqual "33"

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
          , H.button_ "t--toggle-first" { onClick: dispatch <| "ToggleFirst" } "."
          , H.button_ "t--toggle-second" { onClick: dispatch <| "ToggleSecond" } "."
          , H.button_ "t--toggle-both" { onClick: dispatch <| "ToggleBoth" } "."
          , H.button_ "t--inc-initial-count" { onClick: dispatch <| "IncInitialCount" } "."
          ]

        update state = case _ of
          "ToggleFirst" -> pure state { showFirst = not state.showFirst }
          "ToggleSecond" -> pure state { showSecond = not state.showSecond }
          "ToggleBoth" -> pure state { showFirst = not state.showFirst, showSecond = not state.showSecond }
          "IncInitialCount" -> pure state { initialCount = state.initialCount + 1 }
          _ -> pure state

    closureOuter =
      { init: pure { increment: 10 }
      , update: \state -> case _ of
          "IncreaseIncrement" -> pure state { increment = state.increment + 1 }
          _ -> pure state
      , view: \state dispatch ->
          H.fragment
          [ H.button_ "t--increase-increment" { onClick: dispatch <| "IncreaseIncrement" } "."
          , H.p "t--increment" $ show state.increment
          , closureInner state.increment
          ]
      }

    closureInner = wrapWithLocalState (ComponentName "Inner") \increment ->
      { init: pure { count: 0 }
      , update: \state -> case _ of
          "Inc" -> pure state { count = state.count + increment }
          "LongInc" -> fork (delay (Milliseconds 10.0) $> "Inc") *> pure state
          _ -> pure state
      , view: \state dispatch ->
          H.fragment
          [ H.button_ "t--inc" { onClick: dispatch <| "Inc" } "."
          , H.button_ "t--long-inc" { onClick: dispatch <| "LongInc" } "."
          , H.p "t--count" $ show $ state.count
          ]
      }
