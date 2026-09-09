module Test.Main (main) where

import Prelude

import Effect (Effect)
import Test.Component as Component
import Test.Foreign as Foreign
import Test.LocalState as LocalState
import Test.ReactElement as ReactElement
import Test.Spec.Reporter (specReporter)
import Test.Spec.Runner.Node (runSpecAndExitProcess)
import Test.Subscriptions as Subscriptions
import Test.Sync as Sync

main :: Effect Unit
main = runSpecAndExitProcess [specReporter] do
  Foreign.spec
  Component.spec
  LocalState.spec
  Subscriptions.spec
  Sync.spec
  ReactElement.spec
