module Test.Sync (spec) where

import Prelude

import Elmish (ComponentDef, Dispatch, ReactElement, Transition, fork, sync)
import Elmish.HTML.Styled as H
import Elmish.Test (clickOn, find, testComponent, text, waitUntil, (>>))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)

type CountState = { count :: Int }

data ChainMsg = ChainKick | ChainStep1 | ChainStep2

data OrderMsg = OrderKick | OrderAdd String

data InitMsg = InitPrepare

data MixedMsg = MixedKick | MixedIncrement

spec :: Spec Unit
spec = describe "Elmish.Component - sync messages" do

  it "applies a chain of sync messages before the next render" do
    testComponent chainComponent do
      find "p" >> text >>= shouldEqual "The count is: 0"
      clickOn "button.t--kick"
      -- The message dispatched by the click enqueues two further sync messages,
      -- each one level deeper. All three must be processed in a single
      -- synchronous pass (no async round trips), so the final count has to be
      -- visible immediately after the click, without any waiting.
      find "p" >> text >>= shouldEqual "The count is: 1"

  it "processes sync messages in the order they were issued" do
    testComponent orderComponent do
      find "p" >> text >>= shouldEqual "[]"
      clickOn "button.t--kick"
      -- Three sync messages issued by the same update must be processed in the
      -- order they were issued, again all in one synchronous pass.
      find "p" >> text >>= shouldEqual "[\"a\",\"b\",\"c\"]"

  it "applies sync messages issued during init before the first render" do
    testComponent initComponent do
      -- The sync message from init must be processed before the very first
      -- render, so the counter is already incremented.
      find "p" >> text >>= shouldEqual "The count is: 1"

  it "processes sync messages before async commands issued by the same update" do
    testComponent mixedComponent do
      find "p" >> text >>= shouldEqual "The count is: 0"
      clickOn "button.t--kick"
      -- The sync message is processed immediately, before any async command
      -- has had a chance to run...
      find "p" >> text >>= shouldEqual "The count is: 1"
      -- ...whereas the forked (async) message is only processed afterwards.
      waitUntil $ find "p" >> text <#> eq "The count is: 2"

  where
    -- A chain of sync messages: clicking "Kick" enqueues Step1, processing
    -- Step1 enqueues Step2, and processing Step2 increments the counter.
    chainComponent :: ComponentDef ChainMsg CountState
    chainComponent = { init, update, view }
      where
        init :: Transition ChainMsg CountState
        init = pure { count: 0 }

        update :: CountState -> ChainMsg -> Transition ChainMsg CountState
        update s ChainKick = do
          sync ChainStep1
          pure s
        update s ChainStep1 = do
          sync ChainStep2
          pure s
        update s ChainStep2 =
          pure s { count = s.count + 1 }

        view :: CountState -> Dispatch ChainMsg -> ReactElement
        view s dispatch =
          H.div "t--sync"
          [ H.p "" $ "The count is: " <> show s.count
          , H.button_ "t--kick" { onClick: H.handle \_ -> dispatch ChainKick } "Kick"
          ]

    -- A single update issuing several sync messages; each appends a distinct
    -- element to the log, so processing order is observable.
    orderComponent :: ComponentDef OrderMsg { log :: Array String }
    orderComponent = { init, update, view }
      where
        init :: Transition OrderMsg { log :: Array String }
        init = pure { log: [] }

        update :: { log :: Array String } -> OrderMsg -> Transition OrderMsg { log :: Array String }
        update s OrderKick = do
          sync $ OrderAdd "a"
          sync $ OrderAdd "b"
          sync $ OrderAdd "c"
          pure s
        update s (OrderAdd x) = pure s { log = s.log <> [x] }

        view :: { log :: Array String } -> Dispatch OrderMsg -> ReactElement
        view s dispatch =
          H.div "t--sync"
          [ H.p "" $ show s.log
          , H.button_ "t--kick" { onClick: H.handle \_ -> dispatch OrderKick } "Kick"
          ]

    -- An init that issues a sync message before settling on its initial state.
    initComponent :: ComponentDef InitMsg CountState
    initComponent = { init, update, view }
      where
        init :: Transition InitMsg CountState
        init = do
          sync InitPrepare
          pure { count: 0 }

        update :: CountState -> InitMsg -> Transition InitMsg CountState
        update s InitPrepare = pure s { count = s.count + 1 }

        view :: CountState -> Dispatch InitMsg -> ReactElement
        view s dispatch =
          H.div "t--sync"
          [ H.p "" $ "The count is: " <> show s.count
          , H.button_ "t--kick" { onClick: H.handle \_ -> dispatch InitPrepare } "Kick"
          ]

    -- A transition that mixes a sync message with a forked (async) one.
    mixedComponent :: ComponentDef MixedMsg CountState
    mixedComponent = { init, update, view }
      where
        init :: Transition MixedMsg CountState
        init = pure { count: 0 }

        update :: CountState -> MixedMsg -> Transition MixedMsg CountState
        update s MixedKick = do
          sync MixedIncrement
          fork (pure MixedIncrement)
          pure s
        update s MixedIncrement = pure s { count = s.count + 1 }

        view :: CountState -> Dispatch MixedMsg -> ReactElement
        view s dispatch =
          H.div "t--sync"
          [ H.p "" $ "The count is: " <> show s.count
          , H.button_ "t--kick" { onClick: H.handle \_ -> dispatch MixedKick } "Kick"
          ]
