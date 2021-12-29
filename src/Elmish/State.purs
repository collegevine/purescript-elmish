module Elmish.State
    ( StateStrategy
    , dedicatedStorage
    , localState
    ) where

import Prelude

import Data.Maybe (Maybe(..), fromMaybe)
import Data.Nullable (toMaybe)
import Effect (Effect)
import Effect.Ref (Ref)
import Effect.Ref as Ref
import Elmish.React as React

-- | This type represents a strategy of storing UI component state. The strategy
-- | is a function that takes initial state and returns a monadic equivalent of
-- | lens for manipulating the state.
-- |
-- | Currently there are two strategies:
-- |
-- |    * `dedicatedStorage` stores state in a dedicated mutable cell. This
-- |      strategy is used in `Elmish.Component.construct`.
-- |    * `localState` stores state locally on the React component instance - i.e.
-- |      `this.setState`. This strategy is used in
-- |      `Elmish.Component.wrapWithLocalState`.
-- |
-- | The former strategy is more reliable, since React is very lax with
-- | `this.state` and `this.setState` (for example, updates are "eventual", with
-- | no time guarantees). However, the former strategy is not pure (requires
-- | allocating the storage cell), and thus doesn't work with inline embedding
-- | of components.
type StateStrategy state =
    { initialState :: state }
    ->
    { initialize ::
        React.ReactComponentInstance -- ^ component instance for which to initialize the state
        -> Effect Unit

    , getState ::
        React.ReactComponentInstance -- ^ component instance for which to get the state
        -> Effect state

    , setState ::
        React.ReactComponentInstance -- ^ component instance for which to set the state
        -> state               -- ^ state to set
        -> Effect Unit         -- ^ callback to invoke when the operation is complete
        -> Effect Unit
    }


-- | Stores state in a dedicated mutable state. See comment on `StateStrategy`
-- | for explanation.
dedicatedStorage :: forall state. Effect (StateStrategy state)
dedicatedStorage = mkStrategy <$> Ref.new Nothing
    where
    mkStrategy :: Ref (Maybe state) -> StateStrategy state
    mkStrategy stateVar {initialState} =
      { initialize: \_ -> Ref.write (Just initialState) stateVar

      , getState: \_ -> fromMaybe initialState <$> Ref.read stateVar

      , setState: \c s cb -> do
            Ref.write (Just s) stateVar
            React.setState c s (pure unit)
            cb
      }


-- | Stores state on the React component instance - i.e. `this.setState`. See
-- | comment on `StateStrategy`.
localState :: forall state. StateStrategy state
localState {initialState} =
  { initialize: \component ->
      React.assignState component initialState

  , getState: \component -> do
      mState <- toMaybe <$> React.getState component
      pure $ fromMaybe initialState mState

  , setState: React.setState
  }
