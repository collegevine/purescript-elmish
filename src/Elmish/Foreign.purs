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
import Data.Array (fold)
import Data.Either (Either(..), hush)
import Data.FoldableWithIndex (findMapWithIndex)
import Data.Int (fromNumber)
import Data.JSDate (JSDate)
import Data.Maybe (Maybe(..), isJust)
import Data.Nullable (Nullable)
import Data.Symbol (class IsSymbol, reflectSymbol)
import Data.Undefined.NoProblem (Opt, Req)
import Effect (Effect)
import Effect.Uncurried (EffectFn1, EffectFn2)
import Foreign (Foreign) as ForeignReexport
import Foreign (Foreign, isArray, isNull, isUndefined, unsafeFromForeign)
import Foreign.Object as Obj
import Record.Unsafe (unsafeGet)
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

data ValidationResult = Valid | Invalid { path :: String, expected :: String, got :: Foreign }

-- | This class is used to assert that values of a type can be passed from
-- | JavaScript to PureScript without any conversions. Specifically, this class
-- | is defined for primitives (strings, numbers, booleans), arrays, and
-- | records.
class CanReceiveFromJavaScript (a :: Type) where
    validateForeignType :: Foreign -> ValidationResult

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
-- |     derive newtype instance CanPassToJavaScript ButtonType
-- |
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

instance CanPassToJavaScript Json

validatePrimitive :: String -> (Foreign -> Boolean) -> Foreign -> ValidationResult
validatePrimitive expected isValidType x =
  if isValidType x then Valid else Invalid { path: "", got: x, expected }

instance CanPassToJavaScript Foreign
instance CanReceiveFromJavaScript Foreign where validateForeignType _ = Valid

instance CanPassToJavaScript String
instance CanReceiveFromJavaScript String where validateForeignType = validatePrimitive "String" isString

instance CanPassToJavaScript Number
instance CanReceiveFromJavaScript Number where validateForeignType = validatePrimitive "Number" isNumber

instance CanPassToJavaScript Boolean
instance CanReceiveFromJavaScript Boolean where validateForeignType = validatePrimitive "Boolean" isBoolean

instance CanPassToJavaScript JSDate
instance CanReceiveFromJavaScript JSDate where validateForeignType = validatePrimitive "Date" isDate

instance CanPassToJavaScript Int
instance CanReceiveFromJavaScript Int where
    validateForeignType = validatePrimitive "Int" $ isNumber && (isJust <<< fromNumber <<< unsafeFromForeign)


instance CanPassToJavaScript a => CanPassToJavaScript (Obj.Object a)

-- Even though there is a general instance for `Object a`, we still have this
-- special-case `Object Foreign` instance here, because it's faster: we don't
-- have to check every element.
instance CanReceiveFromJavaScript (Obj.Object Foreign) where
  validateForeignType = validatePrimitive "Object" isObject
else instance CanReceiveFromJavaScript a => CanReceiveFromJavaScript (Obj.Object a) where
  validateForeignType v
    | not isObject v = Invalid { path: "", expected: "Object", got: v }
    | otherwise = Obj.foldMaybe invalidElem Valid (unsafeFromForeign v)
    where
      invalidElem (Invalid _) _ _ = Nothing
      invalidElem _ key x = case validateForeignType @a x of
        Valid -> Just Valid
        Invalid invalid -> Just $ Invalid invalid { path = "['" <> key <> "']" <> invalid.path }


instance CanPassToJavaScript (Effect Unit)
else instance CanPassToJavaScript a => CanPassToJavaScript (Effect a)
instance CanReceiveFromJavaScript (Effect Unit) where
    validateForeignType = validatePrimitive "Function" isFunction

instance CanReceiveFromJavaScript a => CanPassToJavaScript (EffectFn1 a Unit)
else instance (CanReceiveFromJavaScript a, CanPassToJavaScript b) => CanPassToJavaScript (EffectFn1 a b)
instance CanPassToJavaScript a => CanReceiveFromJavaScript (EffectFn1 a Unit) where
    validateForeignType = validatePrimitive "Function" isFunction

instance CanReceiveFromJavaScript a => CanPassToJavaScript (EffectFn2 a b Unit)
else instance (CanReceiveFromJavaScript a, CanReceiveFromJavaScript b, CanPassToJavaScript c) => CanPassToJavaScript (EffectFn2 a b c)
instance (CanPassToJavaScript a, CanPassToJavaScript b) => CanReceiveFromJavaScript (EffectFn2 a b Unit) where
    validateForeignType = validatePrimitive "Function" isFunction


instance CanPassToJavaScript a => CanPassToJavaScript (Array a)

-- Even though there is a general instance for `Array a`, we still have this
-- special-case `Array Foreign` instance here, because it's faster: we don't
-- have to check every element.
instance CanReceiveFromJavaScript (Array Foreign) where
    validateForeignType = validatePrimitive "Array" isArray
else instance CanReceiveFromJavaScript a => CanReceiveFromJavaScript (Array a) where
    validateForeignType v
      | not isArray v = Invalid { path: "", expected: "Array", got: v }
      | otherwise = case findMapWithIndex invalidElem (unsafeFromForeign v :: Array Foreign) of
          Nothing -> Valid
          Just { idx, invalid } -> Invalid invalid { path = "[" <> show idx <> "]" <> invalid.path }
      where
        invalidElem idx x = case validateForeignType @a x of
          Valid -> Nothing
          Invalid invalid -> Just { idx, invalid }


instance CanPassToJavaScript a => CanPassToJavaScript (Nullable a)
instance CanReceiveFromJavaScript a => CanReceiveFromJavaScript (Nullable a) where
    validateForeignType v
      | isNull v || isUndefined v = Valid
      | otherwise =
          case validateForeignType @a v of
            Valid -> Valid
            Invalid err -> Invalid err { expected = if err.path == "" then "Nullable " <> err.expected else err.expected }

instance CanPassToJavaScript a => CanPassToJavaScript (Opt a)
instance CanReceiveFromJavaScript a => CanReceiveFromJavaScript (Opt a) where
    validateForeignType = validateForeignType @(Nullable a)

instance CanPassToJavaScript a => CanPassToJavaScript (Req a)
instance CanReceiveFromJavaScript a => CanReceiveFromJavaScript (Req a) where
  validateForeignType = validateForeignType @a

instance (RowToList r rl, CanPassToJavaScriptRecord rl) => CanPassToJavaScript (Record r)
instance (RowToList r rl, CanReceiveFromJavaScriptRecord rl) => CanReceiveFromJavaScript (Record r) where
    validateForeignType v
      | isObject v = validateJsRecord @rl v
      | otherwise = Invalid { path: "", expected: "Object", got: v }


-- This instance allows passing functions of simple arguments to views.
--
-- Note that the argument of the function is `Foreign`, not some generic `a`.
-- This reflects the fact that the JS code may pass anything as argument to the function,
-- and it's the PS code's responsibility to ensure correct type, for example via `readForeign`.
instance CanPassToJavaScript a => CanPassToJavaScript (Foreign -> a)


-- | This class is implementation of `validateForeignType` for records. It
-- | validates a given JS hash (aka "object") against a given type row that
-- | represents a PureScript record, recursively calling
-- | `validateForeignType` for each field.
class CanReceiveFromJavaScriptRecord (rowList :: RowList Type) where
    validateJsRecord :: Foreign -> ValidationResult

instance CanReceiveFromJavaScriptRecord Nil where
    validateJsRecord _ = Valid

else instance (IsSymbol name, CanReceiveFromJavaScript a, CanReceiveFromJavaScriptRecord rl') => CanReceiveFromJavaScriptRecord (Cons name a rl') where
    validateJsRecord v =
        case validHead of
          Invalid err -> Invalid err { path = "." <> fieldName <> err.path }
          Valid -> validateJsRecord @rl' v
        where
            validHead = validateForeignType @a head
            fieldName = reflectSymbol @name Proxy
            head = unsafeGet fieldName (unsafeFromForeign v :: {})


-- | This class is implementation of `CanPassToJavaScript` for records. It
-- | simply iterates over all fields, checking that every field is of a type
-- | that also has an instance of `CanPassToJavaScript`.
class CanPassToJavaScriptRecord (rowList :: RowList Type)
instance CanPassToJavaScriptRecord Nil
else instance (IsSymbol name, CanPassToJavaScript a, CanPassToJavaScriptRecord rl') => CanPassToJavaScriptRecord (Cons name a rl')


-- | Verifies if the given raw JS value is of the right type/shape to be
-- | represented as `a`, and if so, coerces the value to `a`.
readForeign' :: ∀ @a. CanReceiveFromJavaScript a => Foreign -> Either String a
readForeign' v = case validateForeignType @a v of
  Valid -> Right $ unsafeFromForeign v
  Invalid i -> Left $ fold
    [ i.path
    , if i.path == "" then "Expected " else ": expected "
    , i.expected
    , " but got: "
    , showForeign i.got
    ]

-- | Verifies if the given raw JS value is of the right type/shape to be
-- | represented as `a`, and if so, coerces the value to `a`.
readForeign :: ∀ @a. CanReceiveFromJavaScript a => Foreign -> Maybe a
readForeign = hush <<< readForeign'
