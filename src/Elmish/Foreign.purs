module Elmish.Foreign
    ( module ForeignReexport
    , class CanPassToJavaScript
    , class CanReceiveFromJavaScript, validateForeignType, ValidationResult(..)
    , readForeign, readForeign'
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
import Data.Either (Either(..), hush)
import Data.FoldableWithIndex (findMapWithIndex)
import Data.Int (fromNumber)
import Data.JSDate (JSDate)
import Data.List as List
import Data.Maybe (Maybe(..), fromMaybe, isJust)
import Data.Nullable (Nullable, null)
import Data.Symbol (class IsSymbol, reflectSymbol)
import Effect (Effect)
import Effect.Uncurried (EffectFn1, EffectFn2)
import Foreign (Foreign) as ForeignReexport
import Foreign (Foreign, isArray, isNull, unsafeFromForeign, unsafeToForeign)
import Foreign.Object as Obj
import Type.Proxy (Proxy(..))
import Type.RowList (class RowToList, Cons, Nil, RowList)

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

data ValidationResult = Valid | Invalid { path :: List.List String, expected :: String, got :: Foreign }

-- | This class is used to assert that values of a type can be passed from
-- | JavaScript to PureScript without any conversions. Specifically, this class
-- | is defined for primitives (strings, numbers, booleans), arrays, and
-- | records.
class CanReceiveFromJavaScript (a :: Type) where
    validateForeignType :: Proxy a -> Foreign -> ValidationResult

-- | This class is used to assert that values of a type can be passed to
-- | JavaScript code directly (without conversion) and understood by that code.
-- | Specifically, this class is defined for primitives (strings, numbers,
-- | booleans), arrays, and records. This assertion is used in a number of
-- | places that pass complex values to JS code to restrict the set of types
-- | that can be safely passed.
-- |
-- | It is still possible to define instances of this class for other,
-- | non-primitive types, but you have to know what you're doing and make sure
-- | that JS representation is sane and stable. For example, a common trick is
-- | to `newtype`-wrap known JS enumerations to provide type safety:
-- |
-- |     module HTMLButton
-- |        ( ButtonType  -- NOTE: not exporting the constructor
-- |        , typeButton, typeSubmit, typeReset
-- |        , ButtonProps, button
-- |        )
-- |        where
-- |
-- |     newtype ButtonType = ButtonType String
-- |     instance toJsButtonType :: CanPassToJavaScript ButtonType
-- |     typeButton = ButtonType "button" :: ButtonType
-- |     typeSubmit = ButtonType "submit" :: ButtonType
-- |     typeReset = ButtonType "reset" :: ButtonType
-- |
-- |     type ButtonProps =
-- |       { type :: ButtonType
-- |       , ...
-- |       }
-- |
-- |     foreign import button :: ButtonProps -> ReactElement
-- |
class CanPassToJavaScript (a :: Type)

instance tojsJson :: CanPassToJavaScript Json

validatePrimitive :: String -> (Foreign -> Boolean) -> Foreign -> ValidationResult
validatePrimitive expected isValidType x =
  if isValidType x then Valid else Invalid { path: List.Nil, got: x, expected }

instance tojsForeign :: CanPassToJavaScript Foreign
instance fromjsForeign :: CanReceiveFromJavaScript Foreign where validateForeignType _ _ = Valid

instance tojsString :: CanPassToJavaScript String
instance fromjsString :: CanReceiveFromJavaScript String where validateForeignType _ = validatePrimitive "String" isString

instance tojsNumber :: CanPassToJavaScript Number
instance fromjsNumber :: CanReceiveFromJavaScript Number where validateForeignType _ = validatePrimitive "Number" isNumber

instance tojsBoolean :: CanPassToJavaScript Boolean
instance fromjsBoolean :: CanReceiveFromJavaScript Boolean where validateForeignType _ = validatePrimitive "Boolean" isBoolean

instance tojsDate :: CanPassToJavaScript JSDate
instance fromjsDate :: CanReceiveFromJavaScript JSDate where validateForeignType _ = validatePrimitive "Date" isDate

instance tojsStrMap :: CanPassToJavaScript a => CanPassToJavaScript (Obj.Object a)
instance fromjsStrMap :: CanReceiveFromJavaScript (Obj.Object Foreign) where validateForeignType _ = validatePrimitive "Object" isObject

instance tojsInt :: CanPassToJavaScript Int
instance fromjsInt :: CanReceiveFromJavaScript Int where
    validateForeignType _ = validatePrimitive "Int" $ isNumber && (isJust <<< fromNumber <<< unsafeFromForeign)

instance tojsEffectUnit :: CanPassToJavaScript (Effect Unit)
else instance tojsEffect :: CanPassToJavaScript a => CanPassToJavaScript (Effect a)
instance fromjsEffect :: CanReceiveFromJavaScript (Effect Unit) where
    validateForeignType _ = validatePrimitive "Function" isFunction

instance tojsEffectFn1Unit :: CanReceiveFromJavaScript a => CanPassToJavaScript (EffectFn1 a Unit)
else instance tojsEffectFn1 :: (CanReceiveFromJavaScript a, CanPassToJavaScript b) => CanPassToJavaScript (EffectFn1 a b)
instance fromjsEffectFn1 :: CanPassToJavaScript a => CanReceiveFromJavaScript (EffectFn1 a Unit) where
    validateForeignType _ = validatePrimitive "Function" isFunction

instance tojsEffectFn2Unit :: CanReceiveFromJavaScript a => CanPassToJavaScript (EffectFn2 a b Unit)
else instance tojsEffectFn2 :: (CanReceiveFromJavaScript a, CanReceiveFromJavaScript b, CanPassToJavaScript c) => CanPassToJavaScript (EffectFn2 a b c)
instance fromjsEffectFn2 :: (CanPassToJavaScript a, CanPassToJavaScript b) => CanReceiveFromJavaScript (EffectFn2 a b Unit) where
    validateForeignType _ = validatePrimitive "Function" isFunction

instance tojsArray :: CanPassToJavaScript a => CanPassToJavaScript (Array a)
instance fromjsArray :: CanReceiveFromJavaScript a => CanReceiveFromJavaScript (Array a) where
    validateForeignType _ v
      | not isArray v = Invalid { path: List.Nil, expected: "Array", got: v }
      | otherwise = case findMapWithIndex invalidElem (unsafeFromForeign v :: Array Foreign) of
          Nothing -> Valid
          Just { idx, invalid } -> Invalid invalid { path = List.Cons ("[" <> show idx <> "]") invalid.path }
      where
        invalidElem idx x = case validateForeignType (Proxy :: _ a) x of
          Valid -> Nothing
          Invalid invalid -> Just { idx, invalid }

instance tojsNullable :: CanPassToJavaScript a => CanPassToJavaScript (Nullable a)
instance fromjsNullable :: CanReceiveFromJavaScript a => CanReceiveFromJavaScript (Nullable a) where
    validateForeignType _ v
      | isNull $ unsafeToForeign v = Valid
      | otherwise = validateForeignType (Proxy :: _ a) $ unsafeToForeign v

instance tojsRecord :: (RowToList r rl, CanPassToJavaScriptRecord rl) => CanPassToJavaScript (Record r)
instance fromjsRecord :: (RowToList r rl, CanReceiveFromJavaScriptRecord rl) => CanReceiveFromJavaScript (Record r) where
    validateForeignType _ v =
      case validateForeignType (Proxy :: _ (Obj.Object Foreign)) v of
        Valid -> validateJsRecord (Proxy :: _ rl) $ unsafeFromForeign v
        invalid -> invalid

-- This instance allows passing functions of simple arguments to views.
--
-- Note that the argument of the function is `Foreign`, not some generic `a`.
-- This reflects the fact that the JS code may pass anything as argument to the function,
-- and it's the PS code's responsibility to ensure correct type, for example via `readForeign`.
instance tojsPureFunction :: CanPassToJavaScript a => CanPassToJavaScript (Foreign -> a)


-- | This class is implementation of `validateForeignType` for records. It
-- | validates a given JS hash (aka "object") against a given type row that
-- | represents a PureScript record, recursively calling
-- | `validateForeignType` for each field.
class CanReceiveFromJavaScriptRecord (rowList :: RowList Type) where
    validateJsRecord :: Proxy rowList -> Obj.Object Foreign -> ValidationResult

instance recfromjsNil :: CanReceiveFromJavaScriptRecord Nil where
    validateJsRecord _ _ = Valid

else instance recfromjsCons :: (IsSymbol name, CanReceiveFromJavaScript a, CanReceiveFromJavaScriptRecord rl') => CanReceiveFromJavaScriptRecord (Cons name a rl') where
    validateJsRecord _ fs =
        case validHead of
          Invalid err -> Invalid err { path = List.Cons ("." <> fieldName) err.path }
          Valid -> validateJsRecord (Proxy :: _ rl') fs
        where
            validHead = validateForeignType (Proxy :: _ a) head
            fieldName = reflectSymbol (Proxy :: _ name)
            head = fs # Obj.lookup fieldName # fromMaybe foreignNull


-- | This class is implementation of `CanPassToJavaScript` for records. It
-- | simply iterates over all fields, checking that every field is of a type
-- | that also has an instance of `CanPassToJavaScript`.
class CanPassToJavaScriptRecord (rowList :: RowList Type)
instance rectojsNil :: CanPassToJavaScriptRecord Nil
else instance rectojsCons :: (IsSymbol name, CanPassToJavaScript a, CanPassToJavaScriptRecord rl') => CanPassToJavaScriptRecord (Cons name a rl')

-- | Verifies if the given raw JS value is of the right type/shape to be
-- | represented as `a`, and if so, coerces the value to `a`.
readForeign' :: ∀ a. CanReceiveFromJavaScript a => Foreign -> Either String a
readForeign' v = case validateForeignType (Proxy :: _ a) v of
  Valid -> Right $ unsafeFromForeign v
  Invalid i -> Left $ List.fold
    [ List.fold i.path
    , if List.null i.path then "Expected " else ": expected "
    , i.expected
    , " but got: "
    , showForeign i.got
    ]

-- | Verifies if the given raw JS value is of the right type/shape to be
-- | represented as `a`, and if so, coerces the value to `a`.
readForeign :: ∀ a. CanReceiveFromJavaScript a => Foreign -> Maybe a
readForeign = hush <<< readForeign'

foreignNull = unsafeToForeign null :: Foreign
