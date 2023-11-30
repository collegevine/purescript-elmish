-- | This module is an echo of an era gone by, it is deprecated and will be
-- | removed soon.
module Elmish.Opaque
    ( Opaque, wrap, unwrap
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
-- | This type is a wrapper that lets us pass any PureScript values into JS
-- | code, with the expectation that the JS code cannot mess with (inspect,
-- | mutate) these values, but can pass them back to the PureScript code in
-- | messages. This type has instances of `CanPassToJavaScript` and
-- | `CanReceiveFromJavaScript`, which allows it to be passed in React props or
-- | view messages.
-- |
-- | One challenge with this type is that we can't just `unsafeCoerce` its
-- | values back and forth, because that would open a very big hole for data
-- | corruption to get in. To have some protection against it, we add a weak
-- | form of verification: internally values of `Opaque` are represented by a
-- | JavaScript hash with a sole key looking like "ref:name", whose value is the
-- | target of the ref, and where "name" is the first type argument of this
-- | `Opaque`. This way, we have at least _something_ to verify (see the
-- | `CanReceiveFromJavaScript` instance below) that the object passed by the JS
-- | code is not some random value, but actually originated as a `Opaque a` of
-- | the right type.
-- |
-- | Admittedly, this is only weak protection, because the JS code can still,
-- | if it really wanted to, construct a hash like `{ "ref:name": "abracadabra"}`
-- | and pass it to the PureScript code, which would happily
-- | accept the "abracadabra" value as if it was the right type.
-- |
-- | Here are my arguments for why this weak protection is enough:
-- |   1) The JS code has to actually _try_ to be destructive. Can't happen by
-- |      accident.
-- |   2) It's technically impossible to do any better without putting
-- |      significant restrictions on the type `a` (i.e. requiring it to be
-- |      `Generic` or to provide type name, etc.), and without losing some
-- |      performance.
-- |   3) If such corruption proves to be a problem in the future, we can always
-- |      fall back to encoding/decoding `Json`, and pay some performance for
-- |      it.
-- |
newtype Opaque (name :: Symbol) a = Opaque (M.Object a)

-- | Creates an instance of `Opaque`. See comments on it above.
wrap :: ∀ @name a. IsSymbol name => a -> Opaque name a
wrap a = Opaque $ M.singleton (refName @name) a

-- | Deconstructs an instance of `Opaque`. See comments on it above.
unwrap :: ∀ @name a. IsSymbol name => Opaque name a -> a
unwrap (Opaque m) =
    -- This use of `fromJust` is justified, because the `Opaque` constructor is
    -- not exported, and the only two places where values of this type are
    -- constructed (`wrap` above and `CanReceiveFromJavaScript` below) guarantee
    -- that this key will be present.
    unsafePartial $ fromJust $ M.lookup (refName @name) m

refName :: ∀ @name. IsSymbol name => String
refName = "ref:" <> reflectSymbol (Proxy @name)

-- See comments on `Ref` above.
instance IsSymbol name => CanReceiveFromJavaScript (Opaque name a) where
    validateForeignType v =
      case M.lookup sname map of
        Just _ -> Valid
        Nothing -> Invalid { path: "", expected: "Opaque", got: v }
      where
          sname = refName @name
          map = unsafeCoerce v

instance IsSymbol name => CanPassToJavaScript (Opaque name a)
