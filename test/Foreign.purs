module Test.Foreign (spec) where

import Prelude

import Data.Array ((!!))
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Nullable (Nullable, notNull, null, toMaybe)
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
      let readRecord :: forall r a. Homogeneous r a => CanReceiveFromJavaScript (Object a) => Show a => Eq a => Record r -> _
          readRecord rec = read rec `shouldEqual` Just (Obj.fromHomogeneous rec)
      readRecord { foo: "bar", one: "two" }
      readRecord { foo: { x: 1, y: "bar" }, one: { x: 2, y: "two" } }
      readRecord { foo: [1,2,3], one: [4,5,6] }
      readRecord { foo: Obj.fromHomogeneous { x: "1", y: "2" }, one: Obj.empty :: Object String }

    it "Objects and Arrays of Foreign" do
      let readAndAssert :: forall a b. CanReceiveFromJavaScript a => b -> (a -> _) -> _
          readAndAssert x g = case read' x of
            Left err -> fail err
            Right a -> g a

      readAndAssert { foo: "bar", one: 42 } \obj -> do
        (readForeign =<< Obj.lookup "foo" obj) `shouldEqual` Just "bar"
        (readForeign =<< Obj.lookup "one" obj) `shouldEqual` Just 42

      readAndAssert [f "bar", f 42] \arr -> do
        (readForeign =<< arr !! 0) `shouldEqual` Just "bar"
        (readForeign =<< arr !! 1) `shouldEqual` Just 42

    it "reads nullable values" do
      read null `shouldEqual` Just (null :: _ Int)
      read (notNull 42) `shouldEqual` Just (notNull 42)
      (read @{ x :: Nullable { y :: Int } } { x: null :: _ Int })
        `shouldEqual` Just { x: null }

      (read' @(Nullable (Array Int)) null <#> toMaybe) `shouldEqual` Right Nothing
      (read' @(Array (Nullable Int)) [f 42, f 5, f null] <#> map toMaybe) `shouldEqual` Right [Just 42, Just 5, Nothing]

      (read' @(Nullable { x :: Int }) null <#> toMaybe) `shouldEqual` Right Nothing

      let r = read' @(Nullable { x :: Int, y :: Nullable { z :: Int } }) { x: 42, y: null }
      (r <#> toMaybe <#> map _.x) `shouldEqual` Right (Just 42)
      (r <#> toMaybe <#> map _.y <#> map toMaybe) `shouldEqual` Right (Just Nothing)

      let q = read @{ foo :: String, one :: Nullable Int } { foo: "bar", one: null }
      (q <#> _.foo) `shouldEqual` Just "bar"
      (q <#> _.one <#> toMaybe) `shouldEqual` Just Nothing

    it "treats missing record fields as null" do
      read { x: "foo" } `shouldEqual` Just { x: "foo", y: null :: _ Int }

    describe "errors" do
      it "primitive types" do
        (read' @String 42) `shouldEqual` Left "Expected String but got: 42"
        (read' @Number "foo") `shouldEqual` Left "Expected Number but got: \"foo\""
        (read' @Int "foo") `shouldEqual` Left "Expected Int but got: \"foo\""
        (read' @Boolean "foo") `shouldEqual` Left "Expected Boolean but got: \"foo\""
        (read' @(Array Int) "foo") `shouldEqual` Left "Expected Array but got: \"foo\""

      it "nullable" do
        (read' @(Nullable Int) "foo") `shouldEqual` Left "Expected Nullable Int but got: \"foo\""

      it "nullable array" do
        (read' @(Nullable (Array Int)) [f 42, f "foo"]) `shouldEqual` Left "[1]: expected Int but got: \"foo\""
        (read' @(Nullable (Array Int)) [f 42, f 5, f "foo"]) `shouldEqual` Left "[2]: expected Int but got: \"foo\""

      it "nullable record" do
        (read' @(Nullable { x :: Int, y :: Boolean }) { x: 42, y: "foo" })
          `shouldEqual` Left ".y: expected Boolean but got: \"foo\""

        (read' @(Nullable { x :: Int, y :: { z :: Int } }) { x: 42, y: "foo" })
          `shouldEqual` Left ".y: expected Object but got: \"foo\""

        (read' @(Nullable { x :: Int, y :: { z :: Nullable Int } }) { x: 42, y: null })
          `shouldEqual` Left ".y: expected Object but got: <null>"

      it "nested within array" do
        (read' @(Array Int) [f 42, f "foo"]) `shouldEqual` Left "[1]: expected Int but got: \"foo\""
        (read' @(Array Int) [f 42, f 5, f "foo"]) `shouldEqual` Left "[2]: expected Int but got: \"foo\""

      it "nested within record" do
        (read' @{ x :: Int, y :: Boolean } { x: 42, y: "foo" })
          `shouldEqual` Left ".y: expected Boolean but got: \"foo\""

        (read' @{ x :: Int, y :: { z :: Int } } { x: 42, y: "foo" })
          `shouldEqual` Left ".y: expected Object but got: \"foo\""

        (read' @{ x :: Int, y :: { z :: Int } } { x: 42, y: { z: "foo" } })
          `shouldEqual` Left ".y.z: expected Int but got: \"foo\""

        (read' @{ x :: Int, y :: { z :: Int } } { x: 42, y: [] })
          `shouldEqual` Left ".y.z: expected Int but got: <undefined>"

      it "record as Object" do
        (read' @(Object String) { x: "foo", y: 42 })
          `shouldEqual` Left "['y']: expected String but got: 42"
        (read' @(Object Int) { x: "foo", y: 42 })
          `shouldEqual` Left "['x']: expected Int but got: \"foo\""
        (read' @(Object { a :: String }) { x: { a: "foo" }, y: 42 })
          `shouldEqual` Left "['y']: expected Object but got: 42"
        (read' @(Object { a :: String, b :: Object Int }) { x: { a: "foo", b: { z: 1 } }, y: { a: "bar", b: { p: 2, q: "x" } } })
          `shouldEqual` Left "['y'].b['q']: expected Int but got: \"x\""

      it "multiple nesting levels" do
        let input = { a: [{ x: [{ y: f 42 }, { y: f 5 }, { y: f "foo" }]}] }
        let output = read' @{ a :: Array { x :: Array { y :: Int } } } input
        output `shouldEqual` Left ".a[0].x[2].y: expected Int but got: \"foo\""

  where
    read :: forall a @b. CanReceiveFromJavaScript b => a -> Maybe b
    read = readForeign <<< unsafeToForeign

    read' :: forall a @b. CanReceiveFromJavaScript b => a -> Either String b
    read' = readForeign' <<< unsafeToForeign

    f = unsafeToForeign
