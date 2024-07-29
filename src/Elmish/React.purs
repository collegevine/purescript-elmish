module Elmish.React
  ( ReactElement
  , ReactComponent
  , ReactComponentInstance
  , class ValidReactProps
  , class ReactChildren, asReactChildren
  , assignState
  , createElement
  , createElement'
  , empty
  , fragment
  , getState
  , hydrate
  , setState
  , render
  , renderToString
  , text
  , unmount
  , module Ref
  ) where

import Prelude

import Data.Function.Uncurried (Fn3, runFn3)
import Data.Nullable (Nullable)
import Effect (Effect)
import Effect.Uncurried (EffectFn1, EffectFn2, EffectFn3, runEffectFn1, runEffectFn2, runEffectFn3)
import Elmish.Foreign (class CanPassToJavaScript)
import Elmish.React.Ref (Ref, callbackRef) as Ref
import Prim.TypeError (Text, class Fail)
import Unsafe.Coerce (unsafeCoerce)
import Web.DOM as HTML

-- | Instantiated subtree of React DOM. JSX syntax produces values of this type.
foreign import data ReactElement :: Type

instance Semigroup ReactElement where append = appendElement_
instance Monoid ReactElement where mempty = empty

-- | This type represents constructor of a React component with a particular
-- | behavior. The type prameter is the record of props (in React lingo) that
-- | this component expects. Such constructors can be "rendered" into
-- | `ReactElement` via `createElement`.
foreign import data ReactComponent :: Type -> Type

-- | A specific instance of a React component - i.e. an object that has `state`
-- | and `props` properties on it.
foreign import data ReactComponentInstance :: Type

-- | The PureScript import of the React’s `createElement` function. Takes a
-- | component constructor, a record of props, some children, and returns a
-- | React DOM element.
-- |
-- | To represent HTML `data-` attributes, `createElement` supports the
-- | `_data :: Object` prop.
-- |
-- | **Example**
-- |
-- | ```purescript
-- | import Elmish.HTML as H
-- | import Foreign.Object as FO
-- |
-- | H.div
-- |   { _data: FO.fromHomogenous { toggle: "buttons" } }
-- |   [...]
-- | ```
-- |
-- | represents the `<div data-toggle="buttons">` DOM element.
-- |
createElement :: ∀ props content
     . ValidReactProps props
    => ReactChildren content
    => ReactComponent props
    -> props                        -- Props
    -> content                      -- Children
    -> ReactElement
createElement component props content = runFn3 createElement_ component props $ asReactChildren content
foreign import createElement_ :: ∀ props. Fn3 (ReactComponent props) props (Array ReactElement) ReactElement

-- | Variant of `createElement` for creating an element without children.
createElement' :: ∀ props
     . ValidReactProps props
    => ReactComponent props
    -> props                        -- Props
    -> ReactElement
createElement' component props = createElement component props ([] :: Array ReactElement)

-- | Empty React element.
empty :: ReactElement
empty = unsafeCoerce false

-- | Render a plain string as a React element.
text :: String -> ReactElement
text = unsafeCoerce

-- | Wraps multiple React elements as a single one (import of React.Fragment)
fragment :: Array ReactElement -> ReactElement
fragment = createElement fragment_ {}

foreign import fragment_ :: ReactComponent {}
foreign import appendElement_ :: ReactElement -> ReactElement -> ReactElement

-- | Asserts that the given type is a valid React props structure. Currently
-- | there are three rules for what is considered "valid":
-- |
-- | 1. The type must be a record.
-- | 2. The types of all props must be safe to pass to JavaScript,
-- |    which is asserted via the `CanPassToJavaScript` class.
class ValidReactProps (a :: Type)
instance CanPassToJavaScript (Record r) => ValidReactProps (Record r)
else instance
    Fail (Text "React props must be a record with all fields of JavaScript-compatible types")
    => ValidReactProps a

-- | Describes a type that can be used as "content" (aka "children") of a React
-- | JSX element. The three instances below make it possible to use `String` and
-- | `ReactElement` as children directly, without wrapping them in an array.
class ReactChildren a where asReactChildren :: a -> Array ReactElement

instance ReactChildren (Array ReactElement) where asReactChildren = identity
instance ReactChildren String where asReactChildren s = [ unsafeCoerce s ]
instance ReactChildren ReactElement where asReactChildren e = [ e ]

getState :: ∀ state. ReactComponentInstance -> Effect (Nullable state)
getState = runEffectFn1 getState_
foreign import getState_ :: ∀ state. EffectFn1 ReactComponentInstance (Nullable state)

setState :: ∀ state. ReactComponentInstance -> state -> (Effect Unit) -> Effect Unit
setState = runEffectFn3 setState_
foreign import setState_ :: ∀ state. EffectFn3 ReactComponentInstance state (Effect Unit) Unit

-- | The equivalent of `this.state = x`, as opposed to `setState`, which is the
-- | equivalent of `this.setState(x)`. This function is used in a component's
-- | constructor to set the initial state.
assignState :: ∀ state. ReactComponentInstance -> state -> Effect Unit
assignState = runEffectFn2 assignState_
foreign import assignState_ :: ∀ state. EffectFn2 ReactComponentInstance state Unit

-- FFI import of ReactDOM.render
render :: ReactElement -> HTML.Element -> Effect Unit
render = runEffectFn2 render_
foreign import render_ :: EffectFn2 ReactElement HTML.Element Unit

-- FFI import of ReactDOM.hydrate (used to instantiate server-side-rendered
-- components on the client side)
hydrate :: ReactElement -> HTML.Element -> Effect Unit
hydrate = runEffectFn2 hydrate_
foreign import hydrate_ :: EffectFn2 ReactElement HTML.Element Unit

-- FFI import of ReactDOM.renderToString (used for server-side rendering)
foreign import renderToString :: ReactElement -> String

unmount :: HTML.Element -> Effect Unit
unmount = runEffectFn1 unmount_
foreign import unmount_ :: EffectFn1 HTML.Element Unit

-- This instance allows including `ReactElement` in view arguments.
instance CanPassToJavaScript ReactElement
