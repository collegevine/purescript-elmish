module Test.ReactElement (spec) where

import Prelude

import Data.Array (fold)
import Elmish (ReactElement)
import Elmish.HTML.Styled as H
import Elmish.Test (testComponent, text)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)

spec :: Spec Unit
spec = describe "Elmish.React.ReactElement" do
  describe "Monoid instance" do

    it "should have `empty` as identity" do
      (H.div "" "One" <> mempty)
        # shouldBeFragmentOf ["div:One"] "One"
      (mempty <> H.div "" "Two")
        # shouldBeFragmentOf ["div:Two"] "Two"

    it "should append two elements" do
      (H.div "" "One" <> H.span "" "Two")
        # shouldBeFragmentOf ["div:One", "span:Two"] "OneTwo"

    it "should append one fragment and one element" do
      (H.fragment [ H.text "One", H.p "" "Two" ] <> H.text "Three")
        # shouldBeFragmentOf ["text:One", "p:Two", "text:Three"] "One\nTwoThree"

    it "should append one element and one fragment" do
      (H.a "" "One" <> H.fragment [ H.text "Two", H.text "Three" ])
        # shouldBeFragmentOf ["a:One", "text:Two", "text:Three"] "OneTwoThree"

    it "should append two fragments" do
      (H.fragment [ H.b "" "One", H.div "" "Two" ] <> H.fragment [ H.p "" "Three", H.text "Four" ])
        # shouldBeFragmentOf ["b:One", "div:Two", "p:Three", "text:Four"] "One\nTwo\nThreeFour"

    it "should not flatten nested elements" do
      (H.div "" [H.text "One", H.text "Two"] <> H.p "" "Three" <> H.a "" [H.text "Four", H.p "" "Five"])
        # shouldBeFragmentOf ["div:One|Two", "p:Three", "a:Four|Five"] "OneTwo\nThreeFour\nFive"

    it "should be foldable" do
      (fold $ H.text <$> ["One", "Two", "Three"])
        # shouldBeFragmentOf ["text:One", "text:Two", "text:Three"] "OneTwoThree"

  where
    shouldBeFragmentOf expected expectedText r = do
      isFragment r `shouldEqual` true
      showFragment r `shouldEqual` expected
      testComponent { init: pure unit, view: \_ _ -> r, update: \_ _ -> pure unit } do
        text >>= shouldEqual expectedText

    showFragment f = showElement <$> elementChildren f
    showElement e = elementType e <> ":" <> elementText e

foreign import elementChildren :: ReactElement -> Array ReactElement
foreign import elementType :: ReactElement -> String
foreign import elementText :: ReactElement -> String
foreign import isFragment :: ReactElement -> Boolean
