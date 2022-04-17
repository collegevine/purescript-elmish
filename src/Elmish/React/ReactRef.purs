module Elmish.React.ReactRef
  ( ReactRef
  , callbackRef
  )
  where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Elmish.Dispatch ((<?|))
import Elmish.Foreign (class CanPassToJavaScript)
import Unsafe.Coerce (unsafeCoerce)
import Web.HTML (HTMLElement)

data ReactRef

instance CanPassToJavaScript ReactRef

callbackRef :: Maybe HTMLElement -> (HTMLElement -> Effect Unit) -> ReactRef
callbackRef ref setRef = unsafeCoerce $ setRef <?| \r -> case eqByReference r <$> ref of
  Just true -> Nothing
  _ -> Just r

foreign import eqByReference :: forall a. a -> a -> Boolean
