module Elmish.Trace
    ( traceTime
    ) where

import Prelude

foreign import traceTime :: forall a. String -> (Unit -> a) -> a
