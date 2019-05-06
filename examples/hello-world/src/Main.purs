module Main where

import Prelude

import Data.Function.Uncurried (runFn2)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Console as Console
import Web.DOM (Element)
import Web.DOM.Document (toNonElementParentNode) as DOM
import Web.DOM.NonElementParentNode (getElementById) as DOM
import Web.HTML (window) as DOM
import Web.HTML.HTMLDocument (toDocument) as DOM
import Web.HTML.Window (document) as DOM

import Elmish.React as R
import Elmish.React.DOM as R


getElementById :: String -> Effect (Maybe Element)
getElementById id =
    DOM.getElementById id
    =<< (pure <<< DOM.toNonElementParentNode <<< DOM.toDocument)
    =<< DOM.document
    =<< DOM.window

main :: Effect Unit
main = do
    mApp <- getElementById "app"
    case mApp of
        Just app ->
            runFn2 R.reactMount app (R.text "Hello World")
        Nothing ->
            Console.error "Couldn’t find #app container"
