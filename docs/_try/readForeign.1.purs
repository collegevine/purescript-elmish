module Main where

import Prelude

import Data.Foldable (fold)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Console (log)
import Foreign (Foreign, unsafeToForeign)
import Elmish.Foreign (readForeign)
import TryPureScript (p, render, text)

rightData :: Foreign
rightData = unsafeToForeign { x: { y: 42 }, z: "foo" }

badData :: Foreign
badData = unsafeToForeign { x: { y: true }, z: "foo" }

type MyData = { x :: { y :: Int }, z :: String }

callMeFromJavaScript :: Foreign -> String
callMeFromJavaScript f =
  case readForeign f :: Maybe MyData of
    Nothing -> "Incoming data has the wrong shape"
    Just a -> "Got the right data: x.y = " <> show a.x.y <> ", z = " <> a.z

main :: Effect Unit
main =
  render $ fold $ p <<< text <$>
    [ callMeFromJavaScript rightData
    , callMeFromJavaScript badData
    ]
