module Elmish.Boot
    ( BootResult
    , boot
    , boot'
    ) where

import Prelude

import Data.Function.Uncurried (runFn2)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class.Console as Console
import Elmish.Component (ComponentDef, construct)
import Elmish.Dispatch (DispatchError, dispatchMsgFn)
import Elmish.React as React
import Web.DOM.NonElementParentNode (getElementById)
import Web.HTML (window)
import Web.HTML.HTMLDocument (toNonElementParentNode)
import Web.HTML.Window (document)

-- | Possible results of mounting the app root to a DOM element
data BootResult
    = BootOk
    | ElementNotFound { domElementId :: String }

-- | Mounts the given UI component to a DOM element with given ID. If the DOM
-- | element with given ID doesn't exist, logs to console and returns normally.
-- | For a more sophisticated handling of this case, use `boot'`.
boot :: forall msg state.
    { domElementId :: String
    , def :: ComponentDef Aff msg state
    }
    -> Effect Unit
boot { domElementId, def } =
    boot' { domElementId, def, onViewError: Console.error } >>= case _ of
        BootOk ->
            pure unit
        ElementNotFound e ->
            Console.error $ "Element #" <> e.domElementId <> " not found"

-- | Mounts the given UI component to a DOM element with given ID
boot' :: forall msg state.
    { domElementId :: String
    , onViewError :: DispatchError -> Effect Unit
    , def :: ComponentDef Aff msg state
    }
    -> Effect BootResult
boot' { domElementId, onViewError, def } =
    window
    >>= (map toNonElementParentNode <<< document)
    >>= getElementById domElementId
    >>= case _ of
        Nothing ->
            pure $ ElementNotFound { domElementId }
        Just e -> do
            render <- construct def
            runFn2 React.reactMount e (render onError)
            pure BootOk
    where
        onError = dispatchMsgFn onViewError (const $ pure unit)
