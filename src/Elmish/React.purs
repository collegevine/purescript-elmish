module Elmish.React
    ( ReactElement
    , ReactComponent
    , ReactComponentInstance
    , class ValidReactProps, class ValidReactPropsRL
    , class ReactChildren, asReactChildren
    , createElement
    , createElement'
    , getState
    , setState
    ) where

import Prelude

import Data.Function.Uncurried (Fn3, runFn3)
import Data.Nullable (Nullable)
import Effect (Effect)
import Prim.RowList (class RowToList, kind RowList, Cons, Nil)
import Prim.TypeError (Text, class Fail)
import Unsafe.Coerce (unsafeCoerce)
import Elmish.Foreign (class CanPassToJavaScript)

-- | Instantiated subtree of React DOM. JSX syntax produces values of this type.
foreign import data ReactElement :: Type

-- | This type represents constructor of a React component with a particular
-- | behavior. The type prameter is the record of props (in React lingo) that
-- | this component expects. Such constructors can be "rendered" into
-- | `ReactElement` via `createElement`.
foreign import data ReactComponent :: Type -> Type

-- | A specific instance of a React component - i.e. an object that has `state`
-- | and `props` properties on it.
foreign import data ReactComponentInstance :: Type

foreign import createElement_ :: forall props. Fn3 (ReactComponent props) props (Array ReactElement) ReactElement

-- | The PureScript import of the React's `createElement` function. Takes a
-- | component constructor, a record of props, some children, and returns a
-- | React DOM element.
createElement :: forall props content
     . ValidReactProps props
    => ReactChildren content
    => ReactComponent props
    -> props                        -- Props
    -> content                      -- Children
    -> ReactElement
createElement component props content = runFn3 createElement_ component props $ asReactChildren content

-- | Variant of `createElement` for creating an element without children.
createElement' :: forall props
     . ValidReactProps props
    => ReactComponent props
    -> props                        -- Props
    -> ReactElement
createElement' component props = createElement component props ([] :: Array ReactElement)


-- | Asserts that the given type is a valid React props structure. Currently
-- | there are three rules for what is considered "valid":
-- |
-- |     (1) The type must be a record.
-- |     (2) The types of all props must be safe to pass to JavaScript,
-- |         which is asserted via the `CanPassToJavaScript` class.
-- |     (3) There cannot be a prop named 'ref'. Currently we do not support
-- |         React refs, and when we do, the type of that prop will have to
-- |         be restricted to something special and effectful.
class ValidReactProps a
instance validProps ::
    ( RowToList r rl
    , ValidReactPropsRL rl
    , CanPassToJavaScript (Record r)
    )
    => ValidReactProps (Record r)
else instance validPropsNonRecord ::
    Fail InvalidProps
    => ValidReactProps a

-- | Internal implementation detail of the `ValidReactProps` class. This has to be a
-- | separate class due to how rows work at type level.
class ValidReactPropsRL (a :: RowList)
instance validPropsNil :: ValidReactPropsRL Nil
instance validPropsConsRef :: Fail InvalidProps => ValidReactPropsRL (Cons "ref" t r)
else instance validPropsCons :: ValidReactPropsRL (Cons n t r)

-- | Custom error message for the `ValidReactProps` and `ValidReactPropsRL` classes
type InvalidProps = Text "React props must be a record and cannot contain a prop named 'ref'"


-- | Describes a type that can be used as "content" (aka "children") of a React
-- | JSX element. The three instances below make it possible to use `String` and
-- | `ReactElement` as children directly, without wrapping them in an array.
class ReactChildren a where
    asReactChildren :: a -> Array ReactElement

instance reactChildrenArray :: ReactChildren (Array ReactElement) where
    asReactChildren = identity

instance reactChildrenString :: ReactChildren String where
    asReactChildren s = [ unsafeCoerce s ]

instance reactChildrenSingle :: ReactChildren ReactElement where
    asReactChildren e = [ e ]


foreign import getState :: forall state. ReactComponentInstance -> Effect (Nullable state)
foreign import setState :: forall state. Fn3 ReactComponentInstance state (Effect Unit) (Effect Unit)

-- This instance allows including `ReactElement` in view arguments.
instance tojsReactElement :: CanPassToJavaScript ReactElement
