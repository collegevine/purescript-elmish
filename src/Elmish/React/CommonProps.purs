module Elmish.React.CommonProps
    ( CommonProps
    , withCommonProps
    , withKey
    , withPropsUnsafe
    ) where

import Prelude

import Elmish.React (class ValidReactProps, ReactElement, cloneElement)
import Elmish.React.Import (class IsSubsetOf)

-- | Row of props that are common to all React components, without having to
-- | declare them.
type CommonProps = ( key :: String )

-- | Adds a `key` prop to an existing `ReactElement`
withKey :: String -> ReactElement -> ReactElement
withKey key = withCommonProps { key }

-- | To an existing `ReactElement`, adds some props that are member of
-- | `CommonProps`. At the momnent, `CommonProps` has exactly one member
-- | (`key`), so this function is here mostly just as a template for defining a
-- | similar function locally in your project for adding your own project-local
-- | common props.
withCommonProps :: forall props
     . ValidReactProps {|props}
    => IsSubsetOf props CommonProps
    => {|props}
    -> ReactElement
    -> ReactElement
withCommonProps = withPropsUnsafe

-- | A direct import of `React.cloneElement` (see
-- | https://reactjs.org/docs/react-api.html#cloneelement)
withPropsUnsafe :: forall props
     . ValidReactProps {|props}
    => {|props}
    -> ReactElement
    -> ReactElement
withPropsUnsafe = flip cloneElement
