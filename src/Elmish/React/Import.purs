-- | This module provides types to support FFI-importing React components into
-- | Elmish parlance. A typical import of a React component consists of four
-- | parts:
-- |
-- |    * A partial row of required props.
-- |    * A partial row of optional props.
-- |    * Actual FFI-import of the component constructor. This import is weakly
-- |      typed and shouldn't be exported from the module. Consider it internal
-- |      implementation detail.
-- |    * Strongly-typed, PureScript-friendly function that constructs the
-- |      component. The body of such function usually consists of just a call
-- |      to `createElement` (or `createElement'` for childless components), its
-- |      only purpose being the type signature. This function is what should be
-- |      exported for use by consumers.
-- |
-- | Classes and type aliases provided in this module, when applied to the
-- | constructor function, make it possible to pass only partial props to it,
-- | while still ensuring their correct types and presence of non-optional ones.
-- |
-- | Example:
-- |
-- |     // JSX
-- |     // `world` prop is required, `hello` and `highlight` are optional
-- |     export const MyComponent = ({ hello, world, highlight }) =>
-- |       <div>
-- |         <span>{hello || "Hello"}, </span>
-- |         <span style={{ color: highlight ? "red" : "" }}>{world}</span>
-- |       </div>
-- |
-- |
-- |     -- PureScript
-- |     module MyComponent(Props, OptProps, myComponent) where
-- |
-- |     import Elmish.React (createElement)
-- |     import Elmish.React.Import (ImportedReactComponentConstructor, ImportedReactComponent)
-- |
-- |     type Props r = ( world :: String | r )
-- |     type OptProps r = ( hello :: String, highlight :: Boolean | r )
-- |
-- |     myComponent :: ImportedReactComponentConstructor Props OptProps
-- |     myComponent = createElement myComponent_
-- |
-- |     foreign import myComponent_ :: ImportedReactComponent
-- |
-- |
-- |     -- PureScript use site
-- |     import MyComponent (myComponent)
-- |     import Elmish.React.DOM (fragment)
-- |
-- |     view :: ...
-- |     view = H.fragment
-- |       [ myComponent { world: "world" }
-- |       , myComponent { hello: "Goodbye", world: "cruel world!", highlight: true }
-- |       ]
-- |
module Elmish.React.Import
    ( CommonProps
    , EmptyProps
    , ImportedReactComponentConstructor'
    , ImportedReactComponentConstructor
    , ImportedReactComponentConstructorWithContent
    , ImportedReactComponent
    , class IsSubsetOf
    ) where

import Elmish.React (class ReactChildren, class ValidReactProps, ReactComponent, ReactElement)
import Type.Row (type (+))
import Prim.Row as Row

-- | Row of props that are common to all React components, without having to
-- | declare them.
type CommonProps = ( key :: String )

-- | And empty open row. To be used for components that don't have any optional
-- | or any required props.
type EmptyProps (r :: Row Type) = ( | r )

-- | Type of a function used to create a React JSX-imported component that is
-- | generic in such a way as to allow any subset of optional properties
-- | (including an empty subset) to be passed in.
type ImportedReactComponentConstructor' reqProps optProps result =
    forall props
     . IsSubsetOf props (reqProps + optProps + CommonProps)
    => IsSubsetOf (reqProps ()) props
    => ValidReactProps { | props }
    => { | props }
    -> result

-- | Type of a function used to create a React JSX-imported component that
-- | doesn't admit children. The function is generic in such a way as to allow
-- | any subset of optional properties (including an empty subset) to be passed
-- | in.
type ImportedReactComponentConstructor reqProps optProps =
    ImportedReactComponentConstructor' reqProps optProps ReactElement

-- | Type of a function used to create a React JSX-imported component that can
-- | include children. The function is generic in such a way as to allow any
-- | subset of optional properties (including an empty subset) to be passed in.
-- | The children are polymorphic, expressed via the `ReactChildren` type class.
type ImportedReactComponentConstructorWithContent reqProps optProps =
    forall content
     . ReactChildren content
    => ImportedReactComponentConstructor' reqProps optProps (content -> ReactElement)

-- | A React component directly imported from JavaScript.
--
-- NOTE: This type has an unconstrained type parameter, which reflects the fact
-- that React components don't actually have any hard constraints on the props
-- they take. The corollary is that these FFI-imported components are not
-- supposed to be public (which, TBH, applies to all FFI imports), and the type
-- safety is supposed to come from a wrapper function of type
-- `ImportedReactComponentConstructor` (see above), which would have the
-- appropriate props constraints.
type ImportedReactComponent  = forall r. ReactComponent r


-- Asserts that one type row is a (non-strict) subset of the other type row
class IsSubsetOf (subset :: Row Type) (superset :: Row Type)
instance isSubsetOf :: Row.Union subset r superset => IsSubsetOf subset superset
