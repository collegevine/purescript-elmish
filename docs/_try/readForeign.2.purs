module Main where

import Prelude

import Data.Foldable (fold)
import Data.Either (Either(..))
import Effect (Effect)
import Effect.Console (log)
import Foreign (Foreign, unsafeToForeign)
import Elmish.Foreign (readForeign')
import TryPureScript (render, withConsole)

rightData :: Foreign
rightData = unsafeToForeign { x: { y: 42 }, z: "foo" }

badData :: Foreign
badData = unsafeToForeign { x: { y: true }, z: "foo" }

type MyData = { x :: { y :: Int }, z :: String }

callMeFromJavaScript :: Foreign -> String
callMeFromJavaScript f =
  case readForeign f :: _ _ MyData of
    Left err -> "Oops: " <> err
    Right a -> "Got the right data: x.y = " <> show a.x.y <> ", z = " <> a.z

main = render =<< withConsole do
  log $ callMeFromJavaScript rightData
  log $ callMeFromJavaScript badData
