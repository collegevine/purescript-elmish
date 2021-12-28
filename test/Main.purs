module Test.Main (main) where

import Prelude

import Effect (Effect)
import Effect.Aff (launchAff_)
import Elmish.Enzyme as Enzyme
import Elmish.Enzyme.Adapter as Adapter
import Test.Component as Component
import Test.Foreign as Foreign
import Test.Spec.Reporter (specReporter)
import Test.Spec.Runner (runSpec)

foreign import _configureJsDomViaFfi :: Type

main :: Effect Unit
main = do
  Enzyme.configure Adapter.react_16_4
  launchAff_ $ runSpec [specReporter] do
    Foreign.spec
    Component.spec
