module Test.Foreign (spec) where

import Prelude

import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Nullable (Nullable, notNull, null)
import Elmish.Foreign (class CanReceiveFromJavaScript, readForeign, readForeign')
import Foreign (unsafeToForeign)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)

spec :: Spec Unit
spec = describe "Elmish.Foreign" do
  describe "readForeign" do
    it "reads primitive types" do
      read 42 `shouldEqual` Just 42
      read 42 `shouldEqual` Just 42.0
      read "foo" `shouldEqual` Just "foo"
      read false `shouldEqual` Just false
      read ["foo"] `shouldEqual` Just ["foo"]

    it "reads JS objects as records" do
      read [42, 42] `shouldEqual` Just { length: 2 }
      read { foo: "bar", one: "two" } `shouldEqual` Just { foo: "bar", one: "two" }

    it "reads nullable values" do
      read null `shouldEqual` Just (null :: _ Int)
      read (notNull 42) `shouldEqual` Just (notNull 42)
      (read { x: null :: _ Int } :: _ { x :: Nullable { y :: Int } })
        `shouldEqual` Just { x: null }

    it "treats missing record fields as null" do
      read { x: "foo" } `shouldEqual` Just { x: "foo", y: null :: _ Int }

    describe "errors" do
      it "primitive types" do
        (read' 42 :: _ _ String) `shouldEqual` Left "Expected String but got: 42"
        (read' "foo" :: _ _ Number) `shouldEqual` Left "Expected Number but got: \"foo\""
        (read' "foo" :: _ _ Int) `shouldEqual` Left "Expected Int but got: \"foo\""
        (read' "foo" :: _ _ Boolean) `shouldEqual` Left "Expected Boolean but got: \"foo\""
        (read' "foo" :: _ _ (Array Int)) `shouldEqual` Left "Expected Array but got: \"foo\""

      it "nullable" do
        (read' "foo" :: _ _ (Nullable Int)) `shouldEqual` Left "Expected Nullable Int but got: \"foo\""

      it "nested within array" do
        (read' [f 42, f "foo"] :: _ _ (Array Int)) `shouldEqual` Left "[1]: expected Int but got: \"foo\""
        (read' [f 42, f 5, f "foo"] :: _ _ (Array Int)) `shouldEqual` Left "[2]: expected Int but got: \"foo\""

      it "nested within record" do
        (read' { x: 42, y: "foo" } :: _ _ { x :: Int, y :: Boolean })
          `shouldEqual` Left ".y: expected Boolean but got: \"foo\""

        (read' { x: 42, y: "foo" } :: _ _ { x :: Int, y :: { z :: Int } })
          `shouldEqual` Left ".y: expected Object but got: \"foo\""

        (read' { x: 42, y: { z: "foo" } } :: _ _ { x :: Int, y :: { z :: Int } })
          `shouldEqual` Left ".y.z: expected Int but got: \"foo\""

        (read' { x: 42, y: [] } :: _ _ { x :: Int, y :: { z :: Int } })
          `shouldEqual` Left ".y.z: expected Int but got: <null>"

      it "multiple nesting levels" do
        let input = { a: [{ x: [{ y: f 42 }, { y: f 5 }, { y: f "foo" }]}] }
        let output = read' input :: _ _ { a :: Array { x :: Array { y :: Int } } }
        output `shouldEqual` Left ".a[0].x[2].y: expected Int but got: \"foo\""

  where
    read :: forall a b. CanReceiveFromJavaScript b => a -> Maybe b
    read = readForeign <<< unsafeToForeign

    read' :: forall a b. CanReceiveFromJavaScript b => a -> Either String b
    read' = readForeign' <<< unsafeToForeign

    f = unsafeToForeign
