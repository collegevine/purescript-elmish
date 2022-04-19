module Elmish.React.Ref
  ( Ref
  , callbackRef
  )
  where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Uncurried (EffectFn1)
import Elmish.Dispatch ((<?|))
import Elmish.Foreign (class CanPassToJavaScript)
import Unsafe.Coerce (unsafeCoerce)

data Ref (el :: Type)

instance CanPassToJavaScript (Ref a)

callbackRef :: forall el. Maybe el -> (el -> Effect Unit) -> Ref el
callbackRef ref setRef = mkCallbackRef $ setRef <?| \r -> case eqByReference r <$> ref of
  Just true -> Nothing
  _ -> Just r
  where
    mkCallbackRef :: EffectFn1 el Unit -> Ref el
    mkCallbackRef = unsafeCoerce

foreign import eqByReference :: forall a. a -> a -> Boolean
