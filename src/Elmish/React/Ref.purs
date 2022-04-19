module Elmish.React.Ref
  ( Ref
  , callbackRef
  )
  where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Nullable (Nullable)
import Data.Nullable as Nullable
import Effect (Effect)
import Effect.Uncurried (EffectFn1)
import Elmish.Dispatch ((<?|))
import Elmish.Foreign (class CanPassToJavaScript)
import Unsafe.Coerce (unsafeCoerce)

-- | An opaque type representing the type for React `ref` props
data Ref (el :: Type)

instance CanPassToJavaScript (Ref a)

-- | Turns a callback function (`el -> Effect Unit`) into a `Ref`. The callback
-- | function should add the `el` parameter to some state.
callbackRef :: forall el. Maybe el -> (Maybe el -> Effect Unit) -> Ref el
callbackRef ref setRef = mkCallbackRef $ setRef <?| \ref' -> case ref, Nullable.toMaybe ref' of
  Nothing, Nothing -> Nothing
  _, Nothing -> Just Nothing
  Nothing, r -> Just r
  Just r, Just r'
    | eqByReference r r' -> Nothing
    | otherwise -> Just $ Just r'
  where
    mkCallbackRef :: EffectFn1 (Nullable el) Unit -> Ref el
    mkCallbackRef = unsafeCoerce

foreign import eqByReference :: forall a. a -> a -> Boolean
