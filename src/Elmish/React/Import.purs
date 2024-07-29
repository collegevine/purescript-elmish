-- | This module provides types to support FFI-importing React components into
-- | Elmish parlance. A typical import of a React component consists of three
-- | parts:
-- |
-- |    * A row of props, with optional props denoted via `Opt`.
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
-- | This is facilitated by the
-- | https://github.com/paluh/purescript-undefined-is-not-a-problem/ library.
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
-- |     module MyComponent(Props, myComponent) where
-- |
-- |     import Data.Undefined.NoProblem (Opt)
-- |     import Elmish.React (createElement)
-- |     import Elmish.React.Import (ImportedReactComponentConstructor, ImportedReactComponent)
-- |
-- |     type Props = ( world :: String, hello :: Opt String, highlight :: Opt Boolean )
-- |
-- |     myComponent :: ImportedReactComponentConstructor Props
-- |     myComponent = createElement myComponent_
-- |
-- |     foreign import myComponent_ :: ImportedReactComponent
-- |
-- |
-- |     -- PureScript use site
-- |     import MyComponent (myComponent)
-- |     import Elmish.React (fragment) as H
-- |
-- |     view :: ...
-- |     view = H.fragment
-- |       [ myComponent { world: "world" }
-- |       , myComponent { hello: "Goodbye", world: "cruel world!", highlight: true }
-- |       ]
-- |
module Elmish.React.Import
    ( CommonProps
    , ImportedReactComponentConstructor'
    , ImportedReactComponentConstructor
    , ImportedReactComponentConstructorWithContent
    , ImportedReactComponent
    ) where

import Data.Undefined.NoProblem (Opt)
import Data.Undefined.NoProblem.Closed as Closed
import Elmish.React (class ReactChildren, class ValidReactProps, ReactComponent, ReactElement)
import Type.Row (type (+))

-- | Row of props that are common to all React components, without having to
-- | declare them.
type CommonProps r = ( key :: Opt String | r )

-- | Type of a function used to create a React JSX-imported component that is
-- | generic in such a way as to allow only subset of properties to be passed
-- | in, while ensuring that all non-optional props are present and have the
-- | right types.
type ImportedReactComponentConstructor' allowedProps result =
    forall props
     . Closed.Coerce props { | CommonProps + allowedProps }
    => ValidReactProps props
    => props
    -> result

-- | Type of a function used to create a React JSX-imported component that
-- | doesn't admit children. The function is generic in such a way as to allow
-- | only subset of properties to be passed in, while ensuring that all
-- | non-optional props are present and have the right types.
type ImportedReactComponentConstructor allowedProps =
    ImportedReactComponentConstructor' allowedProps ReactElement

-- | Type of a function used to create a React JSX-imported component that can
-- | include children. The function is generic in such a way as to allow only
-- | subset of properties to be passed in, while ensuring that all non-optional
-- | props are present and have the right types. The children are polymorphic,
-- | expressed via the `ReactChildren` type class.
type ImportedReactComponentConstructorWithContent allowedProps =
    forall content
     . ReactChildren content
    => ImportedReactComponentConstructor' allowedProps (content -> ReactElement)

-- | A React component directly imported from JavaScript.
-- |
-- | NOTE: This type has an unconstrained type parameter, which reflects the
-- | fact that React components don't actually have any hard constraints on the
-- | props they take. The corollary is that these FFI-imported components are
-- | not supposed to be public (which, TBH, applies to all FFI imports), and the
-- | type safety is supposed to come from a wrapper function of type
-- | `ImportedReactComponentConstructor` (see above), which would have the
-- | appropriate props constraints.
type ImportedReactComponent  = forall r. ReactComponent r
