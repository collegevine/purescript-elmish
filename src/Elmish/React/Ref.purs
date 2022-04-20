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

-- | Takes the current ref value and a callback function (`el -> Effect Unit`)
-- | and returns a `Ref`. The current ref value is needed so that we can decide
-- | whether the callback function should be run (by comparing the current ref
-- | and the new one by reference). The callback function should add the `el`
-- | parameter to some state. E.g.:
-- |
-- | ```purs
-- | data Message = RefChanged (Maybe HTMLInputElement) | …
-- |
-- | view :: State -> Dispatch Message -> ReactElement
-- | view state dispatch =
-- |   H.input_ "" { ref: callbackRef state.inputElement (dispatch <<< RefChanged), … }
-- | ```
callbackRef :: forall el. Maybe el -> (Maybe el -> Effect Unit) -> Ref el
callbackRef ref setRef = mkCallbackRef $ setRef <?| \ref' -> case ref, Nullable.toMaybe ref' of
  Nothing, Nothing -> Nothing
  Just r, Just r'
    | eqByReference r r' -> Nothing
    | otherwise -> Just $ Just r'
  _, r -> Just r
  where
    mkCallbackRef :: EffectFn1 (Nullable el) Unit -> Ref el
    mkCallbackRef = unsafeCoerce

foreign import eqByReference :: forall a. a -> a -> Boolean
