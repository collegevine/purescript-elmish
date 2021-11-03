module Test.Foreign (spec) where

import Prelude

import Data.Array ((!!))
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Nullable (Nullable, notNull, null)
import Elmish.Foreign (class CanReceiveFromJavaScript, readForeign, readForeign')
import Foreign (unsafeToForeign)
import Foreign.Object (Object)
import Foreign.Object as Obj
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (fail, shouldEqual)
import Type.Row.Homogeneous (class Homogeneous)

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

    it "reads JS objects as homogeneous Object" do
      let readRecord :: forall r a. Homogeneous r a => CanReceiveFromJavaScript a => Show a => Eq a => Record r -> _
          readRecord rec = read rec `shouldEqual` Just (Obj.fromHomogeneous rec)
      readRecord { foo: "bar", one: "two" }
      readRecord { foo: { x: 1, y: "bar" }, one: { x: 2, y: "two" } }
      readRecord { foo: [1,2,3], one: [4,5,6] }
      readRecord { foo: Obj.fromHomogeneous { x: "1", y: "2" }, one: Obj.empty :: Object String }

    it "Objects and Arrays of Foreign" do
      let readAndAssert :: forall a b. CanReceiveFromJavaScript a => b -> (a -> _) -> _
          readAndAssert x f = case read' x of
            Left err -> fail err
            Right a -> f a

      readAndAssert { foo: "bar", one: 42 } \obj -> do
        (readForeign =<< Obj.lookup "foo" obj) `shouldEqual` Just "bar"
        (readForeign =<< Obj.lookup "one" obj) `shouldEqual` Just 42

      readAndAssert [f "bar", f 42] \arr -> do
        (readForeign =<< arr !! 0) `shouldEqual` Just "bar"
        (readForeign =<< arr !! 1) `shouldEqual` Just 42

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
          `shouldEqual` Left ".y.z: expected Int but got: <undefined>"

      it "record as Object" do
        (read' { x: "foo", y: 42 } :: _ _ (Object String))
          `shouldEqual` Left "['y']: expected String but got: 42"
        (read' { x: "foo", y: 42 } :: _ _ (Object Int))
          `shouldEqual` Left "['x']: expected Int but got: \"foo\""
        (read' { x: { a: "foo" }, y: 42 } :: _ _ (Object { a :: String }))
          `shouldEqual` Left "['y']: expected Object but got: 42"
        (read' { x: { a: "foo", b: { z: 1 } }, y: { a: "bar", b: { p: 2, q: "x" } } } :: _ _ (Object { a :: String, b :: Object Int }))
          `shouldEqual` Left "['y'].b['q']: expected Int but got: \"x\""

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
