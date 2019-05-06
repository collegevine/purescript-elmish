module Elmish.React.DOM.Internal where

import Elmish.React.Import (ImportedReactComponent)
import Unsafe.Coerce (unsafeCoerce)

foreign import data CSS :: Type

unsafeCreateDOMComponent :: String -> ImportedReactComponent
unsafeCreateDOMComponent = unsafeCoerce
