module Elmish.React.DOM
    ( empty
    , text
    , fragment
    ) where

import Elmish.React (ReactComponent, ReactElement, createElement)
import Unsafe.Coerce (unsafeCoerce)

-- | Empty React element.
empty :: ReactElement
empty = unsafeCoerce false

-- | Render a plain string as a React element.
text :: String -> ReactElement
text = unsafeCoerce

-- | Wraps multiple React elements as a single one (import of React.Fragment)
fragment :: Array ReactElement -> ReactElement
fragment = createElement fragment_ {}

foreign import fragment_ :: ReactComponent {}
