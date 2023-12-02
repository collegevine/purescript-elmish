module Test.Examples.WrapperComponent where

import Prelude

import Elmish (ComponentDef, (<|))
import Elmish.Component (ComponentName(..), wrapWithLocalState)
import Elmish.HTML.Styled as H

-- | Wraps another component, instantiating it via `wrapWithLocalState`, so that
-- | it would mount/unmount when toggled, and displays two buttons for toggling
-- | it. The host test would click the buttons to show/hide the inner component
-- | and verify that it correctly mounted/unmounted.
wrapperComponent :: ∀ msg state. String -> ComponentDef msg state -> ComponentDef Boolean Boolean
wrapperComponent className inner = { init: pure false, update, view }
  where
    update _ s = pure s

    view s dispatch = H.fragment
      [ H.button_ (className <> " t--show-child") { onClick: dispatch <| true } "Show"
      , H.button_ (className <> " t--hide-child") { onClick: dispatch <| false } "Hide"
      , if s
          then wrapWithLocalState (ComponentName "Inner") (const inner) unit
          else H.empty
      ]
