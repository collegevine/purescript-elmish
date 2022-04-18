module Elmish.React.Ref
  ( Ref
  , callbackRef
  )
  where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Elmish.Dispatch ((<?|))
import Elmish.Foreign (class CanPassToJavaScript)
import Unsafe.Coerce (unsafeCoerce)

data Ref (el :: Type)

instance CanPassToJavaScript (Ref a)

callbackRef :: forall el. Maybe el -> (el -> Effect Unit) -> Ref el
callbackRef ref setRef = unsafeCoerce $ setRef <?| \r -> case eqByReference r <$> ref of
  Just true -> Nothing
  _ -> Just r

foreign import eqByReference :: forall a. a -> a -> Boolean
