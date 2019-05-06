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

import Elmish.React (ReactElement)
import Elmish.React (reactMount) as R
import Elmish.React.DOM (a, div, h1, p, text) as R


main :: Effect Unit
main = do
    mContainer <- getElementById "app"
    case mContainer of
        Just container ->
            runFn2 R.reactMount container helloWorld
        Nothing ->
            Console.error "Couldn’t find #app container"
    where
    getElementById :: String -> Effect (Maybe Element)
    getElementById id =
        DOM.getElementById id
        =<< (pure <<< DOM.toNonElementParentNode <<< DOM.toDocument)
        =<< DOM.document
        =<< DOM.window

helloWorld :: ReactElement
helloWorld =
    R.div {}
        [ R.h1 {} "Hello World"
        , R.p {}
            [ R.text "This is a "
            , R.a { href: "https://www.example.com" } "link"
            , R.text " to example.com."
            ]
        ]
