module Elmish.Dispatch
  ( (<?|)
  , (<|)
  , Dispatch
  , class Handle
  , class HandleEffect
  , class HandleMaybe
  , handle
  , handleEffect
  , handleMaybe
  )
  where

import Prelude

import Data.Maybe (Maybe, maybe)
import Effect (Effect)
import Effect.Uncurried as E
import Safe.Coerce (coerce)
import Type.Equality (class TypeEquals)

-- | A function that a view can use to report messages originating from JS/DOM.
type Dispatch msg = msg -> Effect Unit

infixr 9 handle as <|
infixr 9 handleMaybe as <?|

class Handle msg event f where
    -- | A convenience function to make construction of event handlers with
    -- | arguments (i.e. `EffectFn1`) a bit shorter. The function takes a `Dispatch`
    -- | and a mapping from the event argument to a message which the given
    -- | `Dispatch` accepts, and it's also available in operator form.
    -- |
    -- | The following example demonstrates expected usage of `handle` (in its
    -- | operator form `<|`):
    -- |
    -- |     textarea
    -- |       { value: state.text
    -- |       , onChange: dispatch <| E.textareaText
    -- |       , onMouseDown: dispatch <| TextareaClicked
    -- |       }
    -- |
    handle :: Dispatch msg -> f -> E.EffectFn1 event Unit

class HandleMaybe msg event f where
    handleMaybe :: Dispatch msg -> f -> E.EffectFn1 event Unit

instance (Dispatchable msg output, TypeEquals event input) => Handle msg event (input -> output) where
    handle dispatch f = E.mkEffectFn1 $ dispatchIt dispatch <<< f <<< coerce
else instance Dispatchable msg output => Handle msg event output where
    handle dispatch a = E.mkEffectFn1 \_ -> dispatchIt dispatch a

instance (Dispatchable msg output, TypeEquals event input) => HandleMaybe msg event (input -> Maybe output) where
    handleMaybe dispatch f = E.mkEffectFn1 $ maybe (pure unit) (dispatchIt dispatch) <<< f <<< coerce
else instance Dispatchable msg output => HandleMaybe msg event (Maybe output) where
    handleMaybe dispatch a = E.mkEffectFn1 \_ -> maybe (pure unit) (dispatchIt dispatch) a

class HandleEffect event f where
    handleEffect :: f -> E.EffectFn1 event Unit
instance TypeEquals event input => HandleEffect event (input -> Effect Unit) where
    handleEffect f = E.mkEffectFn1 $ f <<< coerce
else instance HandleEffect event (Effect Unit) where
    handleEffect = E.mkEffectFn1 <<< const

class Dispatchable msg a | a -> msg where
    dispatchIt :: Dispatch msg -> a -> Effect Unit
instance Dispatchable a (Effect a) where
    dispatchIt = (=<<)
else instance Dispatchable a a where
    dispatchIt = ($)
