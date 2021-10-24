-- | This module is an echo of an era gone by, it is deprecated and will be
-- | removed soon.
module Elmish.Ref
    ( Ref, ref, deref
    ) where

import Prelude

import Data.Maybe (Maybe(..), fromJust)
import Data.Symbol (class IsSymbol, reflectSymbol)
import Elmish.Foreign (class CanPassToJavaScript, class CanReceiveFromJavaScript, ValidationResult(..))
import Foreign.Object as M
import Partial.Unsafe (unsafePartial)
import Type.Proxy (Proxy(..))
import Unsafe.Coerce (unsafeCoerce)

-- | An opaque reference for tunneling through JSX code.
-- |
-- | This type is a wrapper that lets us pass any PureScript values into JSX
-- | code, with the expectation that the JSX code cannot mess with (inspect,
-- | mutate) these values, but can pass them back to the PureScript code in
-- | messages. This type has instances of `CanPassToJavaScript` and
-- | `CanReceiveFromJavaScript`, which allows it to be passed in React props or
-- | view messages.
-- |
-- | One challenge with this type is that we can't just `unsafeCoerce` its
-- | values back and forth, because that would open a very big hole for data
-- | corruption to get in. To have some protection against it, we add a weak
-- | form of verification: internally values of `Ref` are represented by a
-- | JavaScript hash with a sole key looking like "ref:name", whose value is the
-- | target of the ref, and where "name" is the first type argument of this
-- | `Ref`. This way, we have at least _something_ to verify (see the
-- | `CanReceiveFromJavaScript` instance below) that the object passed by the
-- | JSX code is not some random value, but actually originated as a `Ref a` of
-- | the right type.
-- |
-- | Admittedly, this is only weak protection, because the JSX code can still,
-- | if it really wanted to, construct a hash like `{ "ref:name": "abracadabra"}`
-- | and pass it to the PureScript code, which would happily
-- | accept the "abracadabra" value as if it was the right type.
-- |
-- | Here are my arguments for why this weak protection is enough:
-- |   1) The JSX code has to actually _try_ to be destructive. Can't happen by
-- |      accident.
-- |   2) It's technically impossible to do any better without putting
-- |      significant restrictions on the type `a` (i.e. requiring it to be
-- |      `Generic` or to provide type name, etc.), and without losing some
-- |      performance.
-- |   3) If such corruption proves to be a problem in the future, we can always
-- |      fall back to encoding/decoding `Json`, and pay some performance for it.
-- |
newtype Ref (name :: Symbol) a = Ref (M.Object a)

-- | Creates an instance of `Ref`. See comments on it above.
ref :: ∀ name a. IsSymbol name => a -> Ref name a
ref a = Ref $ M.singleton (refName (Proxy :: _ name)) a

-- | Deconstructs an instance of `Ref`. See comments on it above.
deref :: ∀ name a. IsSymbol name => Ref name a -> a
deref (Ref m) =
    -- This use of `fromJust` is justified, because the `Ref` constructor is not exported,
    -- and the only two places where values of this type are constructed (`ref` above and
    -- `CanReceiveFromJavaScript` below) guarantee that this key will be present.
    unsafePartial $ fromJust $ M.lookup (refName (Proxy :: _ name)) m

refName :: ∀ name. IsSymbol name => Proxy name -> String
refName p = "ref:" <> reflectSymbol p

-- See comments on `Ref` above.
instance readjsRef :: IsSymbol name => CanReceiveFromJavaScript (Ref name a) where
    validateForeignType _ v =
      case M.lookup sname map of
        Just _ -> Valid
        Nothing -> Invalid { path: "", expected: "Ref", got: v }
      where
          sname = refName (Proxy :: _ name)
          map = unsafeCoerce v

instance writejsRef :: IsSymbol name => CanPassToJavaScript (Ref name a)
