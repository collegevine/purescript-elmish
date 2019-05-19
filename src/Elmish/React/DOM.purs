module Elmish.React.DOM
    ( empty
    , text
    , fragment

    , render
    , unmountComponentAtNode
    ) where

import Prelude

import Effect (Effect)
import Elmish.React (ReactComponent, ReactElement, createElement)
import Unsafe.Coerce (unsafeCoerce)
import Web.DOM (Element)

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

foreign import render :: ReactElement -> Element -> Effect Unit
foreign import unmountComponentAtNode :: Element -> Effect Unit
