module Elmish.Dispatch
  ( (<|)
  , Dispatch
  , class Handle
  , class HandleEffect
  , handle
  , handleEffect
  )
  where

import Prelude

import Data.Maybe (Maybe, maybe)
import Effect (Effect)
import Effect.Uncurried as E
import Safe.Coerce (coerce)
import Type.Equality (class TypeEquals, proof)

-- | A function that a view can use to report messages originating from JS/DOM.
type Dispatch msg = msg -> Effect Unit

infixr 9 handle as <|

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
    -- |       , onChange: dispatch <| E.inputText
    -- |       , onMouseDown: dispatch <| TextareaClicked
    -- |       }
    -- |
    handle :: Dispatch msg -> f -> E.EffectFn1 event Unit

instance TypeEquals res msg => Handle msg event (event -> Maybe res) where
    handle dispatch f = E.mkEffectFn1 $ maybe (pure unit) dispatch <<< coerce <<< f
else instance TypeEquals res msg => Handle msg event (event -> res) where
    handle dispatch f = E.mkEffectFn1 $ dispatch <<< coerce <<< f
else instance TypeEquals res msg => Handle msg event (event -> Effect (Maybe res)) where
    handle dispatch f = E.mkEffectFn1 $ maybe (pure unit) dispatch <=< (map coerce <<< f)
else instance TypeEquals res msg => Handle msg event (event -> Effect res) where
    handle dispatch f = E.mkEffectFn1 $ dispatch <=< (coerce <<< f)
else instance TypeEquals res msg => Handle msg event (Effect res) where
    handle dispatch msg = E.mkEffectFn1 \_ -> dispatch =<< coerce msg
else instance TypeEquals res msg => Handle msg event res where
    handle dispatch msg = E.mkEffectFn1 \_ -> dispatch $ coerce msg

class HandleEffect event f where
    handleEffect :: f -> E.EffectFn1 event Unit
instance TypeEquals event input => HandleEffect event (input -> Effect Unit) where
    handleEffect f = E.mkEffectFn1 $ f <<< coerce
else instance HandleEffect event (Effect Unit) where
    handleEffect = E.mkEffectFn1 <<< const

