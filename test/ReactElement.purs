module Test.ReactElement (spec) where

import Prelude

import Data.Array (fold)
import Elmish (ReactElement)
import Elmish.HTML.Styled as H
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)

spec :: Spec Unit
spec = describe "Elmish.React.ReactElement" do
  describe "Monoid instance" do

    it "should have `empty` as identity" do
      (H.div "" "One" <> mempty)
        `shouldBeFragmentOf` ["div:One"]
      (mempty <> H.div "" "Two")
        `shouldBeFragmentOf` ["div:Two"]

    it "should append two elements" do
      (H.div "" "One" <> H.span "" "Two")
        `shouldBeFragmentOf` ["div:One", "span:Two"]

    it "should append one fragment and one element" do
      (H.fragment [ H.text "One", H.p "" "Two" ] <> H.text "Three")
        `shouldBeFragmentOf` ["text:One", "p:Two", "text:Three"]

    it "should append one element and one fragment" do
      (H.a "" "One" <> H.fragment [ H.text "Two", H.text "Three" ])
        `shouldBeFragmentOf` ["a:One", "text:Two", "text:Three"]

    it "should append two fragments" do
      (H.fragment [ H.b "" "One", H.div "" "Two" ] <> H.fragment [ H.p "" "Three", H.text "Four" ])
        `shouldBeFragmentOf` ["b:One", "div:Two", "p:Three", "text:Four"]

    it "should not flatten nested elements" do
      (H.div "" [H.text "One", H.text "Two"] <> H.p "" "Three" <> H.a "" [H.text "Four", H.p "" "Five"])
        `shouldBeFragmentOf` ["div:One|Two", "p:Three", "a:Four|Five"]

    it "should be foldable" do
      (fold $ H.text <$> ["One", "Two", "Three"])
        `shouldBeFragmentOf` ["text:One", "text:Two", "text:Three"]

  where
    shouldBeFragmentOf r expected = do
      isFragment r `shouldEqual` true
      showFragment r `shouldEqual` expected

    showFragment f = showElement <$> elementChildren f
    showElement e = elementType e <> ":" <> elementText e

foreign import elementChildren :: ReactElement -> Array ReactElement
foreign import elementType :: ReactElement -> String
foreign import elementText :: ReactElement -> String
foreign import isFragment :: ReactElement -> Boolean
