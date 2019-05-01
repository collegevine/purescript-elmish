module Elmish.React.Import
    ( EmptyProps
    , ImportedReactComponentConstructor'
    , ImportedReactComponentConstructor
    , ImportedReactComponentConstructorWithContent
    , ImportedReactComponent
    , class IsSubsetOf
    ) where

import Elmish.React (class ReactChildren, class ValidReactProps, ReactComponent, ReactElement)
import Type.Row (type (+))
import Prim.Row as Row

-- | And empty open row. To be used for components that don't have any optional
-- | or any required props.
type EmptyProps (r :: #Type) = ( | r )

-- | Type of a function used to create a React JSX-imported component that is
-- | generic in such a way as to allow any subset of optional properties
-- | (including an empty subset) to be passed in.
type ImportedReactComponentConstructor' reqProps optProps result =
    forall props
     . IsSubsetOf props (reqProps + optProps + ())
    => IsSubsetOf (reqProps + ()) props
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
class IsSubsetOf (subset :: # Type) (superset :: # Type)
instance isSubsetOf :: Row.Union subset r superset => IsSubsetOf subset superset
