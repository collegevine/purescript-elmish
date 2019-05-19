module Elmish.Browser
    ( sandbox
    , module Exported
    ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Exception (throw)
import Elmish.Component (ComponentDef, construct)
import Elmish.Dispatch (dispatchMsgFn)
import Elmish.React.DOM as ReactDOM
import Web.DOM.ParentNode (QuerySelector(..)) as Exported
import Web.DOM.ParentNode (QuerySelector(..), querySelector)
import Web.HTML (window) as HTML
import Web.HTML.HTMLDocument (toParentNode) as HTMLDocument
import Web.HTML.Window (document) as HTML

sandbox :: forall msg state. QuerySelector -> ComponentDef Aff msg state -> Effect Unit
sandbox selector@(QuerySelector rawSelector) component = do
    window <- HTML.window
    documentParentNode <- HTMLDocument.toParentNode <$> HTML.document window
    mDOMElement <- querySelector selector documentParentNode
    case mDOMElement of
        Nothing ->
            throw $
                "Couldn’t find any element matching '" <> rawSelector <>
                "' selector.\
                \ Please make sure it’s defined in your HTML document."
        Just domElement -> do
            renderFn <- construct component
            let reactElement = renderFn $ dispatchMsgFn onError onMessage
                onError = throw
                onMessage = const $ pure unit
            ReactDOM.render reactElement domElement
