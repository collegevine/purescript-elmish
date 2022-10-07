module Test.Main (main) where

import Prelude

import Effect (Effect)
import Effect.Aff (launchAff_)
import Test.Component as Component
import Test.Foreign as Foreign
import Test.LocalState as LocalState
import Test.Spec.Reporter (specReporter)
import Test.Spec.Runner (runSpec)

main :: Effect Unit
main = launchAff_ $ runSpec [specReporter] do
  Foreign.spec
  Component.spec
  LocalState.spec
