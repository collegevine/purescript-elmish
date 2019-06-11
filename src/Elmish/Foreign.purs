module Elmish.Foreign
    ( module ForeignReexport
    , class CanPassToJavaScript
    , class CanReceiveFromJavaScript, isForeignOfCorrectType, readForeign
    , showForeign

    , Arguments
    , argumentsToArray_
    , getArgument
    , mkVarArgEff_

    -- These exports are required by PureScript's export rules, but they
    -- are really just internal implementation details.
    , class CanReceiveFromJavaScriptRecord, validateJsRecord
    , class CanPassToJavaScriptRecord
    ) where

import Prelude

import Data.Argonaut.Core (Json)
import Data.Int (fromNumber)
import Data.JSDate (JSDate)
import Data.Maybe (Maybe(..), isJust, maybe)
import Data.Nullable (Nullable)
import Data.Symbol (class IsSymbol, SProxy(..), reflectSymbol)
import Data.Traversable (all)
import Effect (Effect)
import Effect.Uncurried (EffectFn1, EffectFn2)
import Foreign (Foreign) as ForeignReexport
import Foreign (Foreign, isArray, isNull, unsafeFromForeign, unsafeToForeign)
import Foreign.Object as Obj
import Type.Proxy (Proxy(..))
import Type.RowList (class RowToList, Cons, Nil, RLProxy(RLProxy), kind RowList)

-- | Type of the `arguments` object in a JS function (https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/arguments).
foreign import data Arguments :: Type

-- | Creates a JS function that takes a variable number of args (via
-- | `arguments`) and calls the provided effectful continuation, passing the
-- | arguments as an array.
foreign import mkVarArgEff_ :: (Arguments -> Effect Unit) -> Foreign

-- | Core logic of `getArgument`.
foreign import getArgument_ :: Arguments -> Int -> (Foreign -> Maybe Foreign) -> (Maybe Foreign) -> Maybe Foreign

-- | Gets the value at a specified index of an `Arguments` object.
-- | Returns `Nothing` if there are not enough arguments.
getArgument :: Arguments -> Int -> Maybe Foreign
getArgument args index =
    getArgument_ args index Just Nothing

-- | Creates a new `Array` from an `Arguments` object.
foreign import argumentsToArray_ :: Arguments -> Array Foreign

foreign import isString :: Foreign -> Boolean
foreign import isNumber :: Foreign -> Boolean
foreign import isBoolean :: Foreign -> Boolean
foreign import isDate :: Foreign -> Boolean
foreign import isObject :: Foreign -> Boolean
foreign import isFunction :: Foreign -> Boolean
foreign import showForeign :: Foreign -> String

-- | This class is used to assert that values of a type can be passed from
-- | JavaScript to PureScript without any conversions. Specifically, this class
-- | is defined for primitives (strings, numbers, booleans), arrays, and
-- | records.
class CanReceiveFromJavaScript a where
    isForeignOfCorrectType :: Proxy a -> Foreign -> Boolean

-- | This class is used to assert that values of a type can be passed to
-- | JavaScript code directly (without conversion) and understood by that code.
-- | Specifically, this class is defined for primitives (strings, numbers,
-- | booleans), arrays, and records. This assertion is used in a number of
-- | places that pass complex values to JS code to restrict the types that can
-- | be safely passed.
class CanPassToJavaScript a

instance tojsJson :: CanPassToJavaScript Json

instance tojsForeign :: CanPassToJavaScript Foreign
instance fromjsForeign :: CanReceiveFromJavaScript Foreign where isForeignOfCorrectType _ _ = true

instance tojsString :: CanPassToJavaScript String
instance fromjsString :: CanReceiveFromJavaScript String where isForeignOfCorrectType _ = isString

instance tojsNumber :: CanPassToJavaScript Number
instance fromjsNumber :: CanReceiveFromJavaScript Number where isForeignOfCorrectType _ = isNumber

instance tojsBoolean :: CanPassToJavaScript Boolean
instance fromjsBoolean :: CanReceiveFromJavaScript Boolean where isForeignOfCorrectType _ = isBoolean

instance tojsDate :: CanPassToJavaScript JSDate
instance fromjsDate :: CanReceiveFromJavaScript JSDate where isForeignOfCorrectType _ = isDate

instance tojsStrMap :: CanPassToJavaScript a => CanPassToJavaScript (Obj.Object a)
instance fromjsStrMap :: CanReceiveFromJavaScript (Obj.Object Foreign) where isForeignOfCorrectType _ = isObject

instance tojsInt :: CanPassToJavaScript Int
instance fromjsInt :: CanReceiveFromJavaScript Int where
    isForeignOfCorrectType _ v = isNumber v && (isJust $ fromNumber $ unsafeFromForeign v)

instance tojsEffectFn1 :: (CanReceiveFromJavaScript a, CanPassToJavaScript b) => CanPassToJavaScript (EffectFn1 a b)
instance fromjsEffectFn1 :: CanPassToJavaScript a => CanReceiveFromJavaScript (EffectFn1 a Unit) where
    isForeignOfCorrectType _ = isFunction

instance tojsEffectFn2 :: (CanReceiveFromJavaScript a, CanReceiveFromJavaScript b, CanPassToJavaScript c) => CanPassToJavaScript (EffectFn2 a b c)
instance fromjsEffectFn2 :: (CanPassToJavaScript a, CanPassToJavaScript b) => CanReceiveFromJavaScript (EffectFn2 a b Unit) where
    isForeignOfCorrectType _ = isFunction

instance tojsArray :: CanPassToJavaScript a => CanPassToJavaScript (Array a)
instance fromjsArray :: CanReceiveFromJavaScript a => CanReceiveFromJavaScript (Array a) where
    isForeignOfCorrectType _ v =
        isArray v && all (isForeignOfCorrectType (Proxy :: Proxy a)) (unsafeFromForeign v :: Array Foreign)

instance tojsNullable :: CanPassToJavaScript a => CanPassToJavaScript (Nullable a)
instance fromjsNullable :: CanReceiveFromJavaScript a => CanReceiveFromJavaScript (Nullable a) where
    isForeignOfCorrectType _ v =
        (isNull $ unsafeToForeign v)
        || (isForeignOfCorrectType (Proxy :: Proxy a) $ unsafeToForeign v)

instance tojsRecord :: (RowToList r rl, CanPassToJavaScriptRecord rl) => CanPassToJavaScript (Record r)
instance fromjsRecord :: (RowToList r rl, CanReceiveFromJavaScriptRecord rl) => CanReceiveFromJavaScript (Record r) where
    isForeignOfCorrectType _ = maybe false (validateJsRecord (RLProxy :: RLProxy rl)) <<< readForeign


-- This instance allows passing functions of simple arguments to views.
--
-- Note that the argument of the function is `Foreign`, not some generic `a`.
-- This reflects the fact that the JS code may pass anything as argument to the function,
-- and it's the PS code's responsibility to ensure correct type, for example via `readForeign`.
instance tojsPureFunction :: CanPassToJavaScript a => CanPassToJavaScript (Foreign -> a)


-- | This class is implementation of `isForeignOfCorrectType` for records. It
-- | validates a given JS hash (aka "object") against a given type row that
-- | represents a PureScript record, recursively calling
-- | `isForeignOfCorrectType` for each field.
class CanReceiveFromJavaScriptRecord rowList where
    validateJsRecord :: RLProxy rowList -> Obj.Object Foreign -> Boolean

instance recfromjsNil :: CanReceiveFromJavaScriptRecord Nil where
    validateJsRecord _ _ = true

instance recfromjsCons :: (IsSymbol name, CanReceiveFromJavaScript a, CanReceiveFromJavaScriptRecord rl') => CanReceiveFromJavaScriptRecord (Cons name a rl') where
    validateJsRecord _ fs = validHead && validTail
        where
            validTail = validateJsRecord (RLProxy :: RLProxy rl') fs
            validHead = case Obj.lookup (reflectSymbol (SProxy :: SProxy name)) fs of
                Nothing -> false
                Just a -> isForeignOfCorrectType (Proxy :: Proxy a) a


-- | This class is implementation of `CanPassToJavaScript` for records. It
-- | simply iterates over all fields, checking that every field is of a type
-- | that also has an instance of `CanPassToJavaScript`.
class CanPassToJavaScriptRecord (rowList :: RowList)
instance rectojsNil :: CanPassToJavaScriptRecord Nil
instance rectojsCons :: (IsSymbol name, CanPassToJavaScript a, CanPassToJavaScriptRecord rl') => CanPassToJavaScriptRecord (Cons name a rl')


-- | Verifies if the given raw JS value is of the right type/shape to be
-- | represented as `a`, and if so, coerces the value to `a`.
readForeign :: ∀ a. CanReceiveFromJavaScript a => Foreign -> Maybe a
readForeign v | isForeignOfCorrectType (Proxy :: Proxy a) v = Just $ unsafeFromForeign v
readForeign _ = Nothing
