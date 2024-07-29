module Elmish.React.Internal
  ( Field(..)
  , getField
  , setField
  ) where

import Prelude

import Data.Maybe (Maybe)
import Data.Symbol (class IsSymbol, reflectSymbol)
import Effect (Effect)
import Effect.Uncurried (EffectFn2, EffectFn3, runEffectFn2, runEffectFn3)
import Elmish.Foreign (class CanPassToJavaScript, class CanReceiveFromJavaScript, Foreign, readForeign)
import Elmish.React (ReactComponentInstance)
import Type.Proxy (Proxy(..))

data Field (f :: Symbol) (a :: Type) = Field

getField :: ∀ f a. CanReceiveFromJavaScript a => IsSymbol f => Field f a -> ReactComponentInstance -> Effect (Maybe a)
getField _ object = runEffectFn2 getField_ (reflectSymbol $ Proxy @f) object <#> readForeign @a
foreign import getField_ :: EffectFn2 String ReactComponentInstance Foreign

setField :: ∀ f a. CanPassToJavaScript a => IsSymbol f => Field f a -> a -> ReactComponentInstance -> Effect Unit
setField _ = runEffectFn3 setField_ $ reflectSymbol $ Proxy @f
foreign import setField_ :: ∀ a. EffectFn3 String a ReactComponentInstance Unit
