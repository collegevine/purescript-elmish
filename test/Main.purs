module Test.Main (main) where

import Prelude

import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Elmish.Enzyme as Enzyme
import Elmish.Enzyme.Adapter as Adapter
import Test.Component as Component
import Test.Foreign as Foreign
import Test.LocalState as LocalState
import Test.Spec.Reporter (specReporter)
import Test.Spec.Runner (runSpec)
import Debug (spy)

foreign import _configureJsDomViaFfi :: Type

main :: Effect Unit
main = launchAff_ $ do
  adapter <- Adapter.react_16_4
  let _ = spy "test" adapter
  liftEffect $ Enzyme.configure adapter
  runSpec [specReporter] do
    Foreign.spec
    Component.spec
    LocalState.spec
