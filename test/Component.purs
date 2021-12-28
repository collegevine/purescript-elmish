module Test.Component (spec) where

import Prelude

import Elmish (ComponentDef)
import Elmish.Enzyme (clickOn, find, testComponent, text, (>>))
import Elmish.HTML.Styled as H
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)

spec :: Spec Unit
spec = describe "Elmish.Component" do
  it "can mount and drive a basic component" do
    testComponent def do
      find "p" >> text >>= shouldEqual "The count is: 0"
      clickOn "button.t--inc"
      find "p" >> text >>= shouldEqual "The count is: 1"
      clickOn "button.t--inc"
      find "p" >> text >>= shouldEqual "The count is: 2"
      clickOn "button.t--dec"
      find "p" >> text >>= shouldEqual "The count is: 1"

type State = { count :: Int }
data Message = Inc | Dec

def :: ComponentDef Message State
def = { init, view, update }
  where
    init = pure { count: 0 }

    view state dispatch =
      H.div ""
      [ H.p "" $ "The count is: " <> show state.count
      , H.button_ "t--inc" { onClick: dispatch Inc } "Inc"
      , H.button_ "t--dec" { onClick: dispatch Dec } "Dec"
      ]

    update s Inc = pure s { count = s.count + 1 }
    update s Dec = pure s { count = s.count - 1 }
