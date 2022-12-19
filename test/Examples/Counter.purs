module Test.Examples.Counter
  ( State
  , Message(..)
  , def
  , init
  , view
  , update
  ) where

import Prelude

import Elmish (ComponentDef, Dispatch, ReactElement, Transition, (<|))
import Elmish.HTML.Styled as H

type State = { count :: Int }
data Message = Inc | Dec

def :: { initialCount :: Int } -> ComponentDef Message State
def args = { init: init args, view, update }

init :: { initialCount :: Int } -> Transition Message State
init { initialCount } = pure { count: initialCount }

view :: State -> Dispatch Message -> ReactElement
view state dispatch =
  H.div "t--counter"
  [ H.p "" $ "The count is: " <> show state.count
  , H.button_ "t--inc" { onClick: dispatch <| Inc } "Inc"
  , H.button_ "t--dec" { onClick: dispatch <| Dec } "Dec"
  ]

update :: State -> Message -> Transition Message State
update s Inc = pure s { count = s.count + 1 }
update s Dec = pure s { count = s.count - 1 }
