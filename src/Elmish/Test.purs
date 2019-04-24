module Elmish.Test
    ( runUI
    , message
    , assert
    , getState
    ) where

import Prelude

import Control.Monad.State (StateT, evalStateT, get, gets, lift, put)
import Data.Traversable (for_)
import Elmish.Component (Transition(..))

type TestMachineState m message state =
    { state :: state
    , update :: state -> message -> Transition m message state
    }

type TestMachine m message state = StateT (TestMachineState m message state) m

-- | A test harness for UI state machines.
-- |
-- | This function takes an "update" function, initial state, and a list of
-- | messages that are to be fed into the state machine, expressed as a series
-- | of monadic operations. It then runs the state machine through those
-- | messages, taking detours to process any new messages that the machine
-- | itself produces (if any).
-- |
-- | Example:
-- |
-- |     import MyComponent as C
-- |     import Elmish.Test as T
-- |
-- |     T.runUI C.update C.initialState do
-- |         T.message C.Next
-- |         T.assert \s -> equal s.pageIndex 1
-- |         T.message C.Next
-- |         T.assert \s -> equal s.pageIndex 2
-- |         T.message C.Back
-- |         T.assert \s -> equal s.pageIndex 1
-- |
runUI :: forall m message state
     . Monad m
    => (state -> message -> Transition m message state)    -- ^ UI update function
    -> Transition m message state                          -- ^ initial state
    -> TestMachine m message state Unit
    -> m Unit
runUI update (Transition initialState initialCmds) transitions =
    evalStateT
        (runCommands initialCmds *> transitions)
        { state: initialState, update }

-- | Feeds a message into the component being tested. If the component produces
-- | any commands as a result of the update, runs through those commands as
-- | well. See example on `runUI`.
message :: forall m message state
     . Monad m
    => message
    -> TestMachine m message state Unit
message msg = do
    machine <- get
    let Transition state1 cmds = machine.update machine.state msg
    put $ machine { state = state1 }

    -- If the update returned any message-producing effects, we run them
    -- to get a message out of each, then run the component through that
    -- message recursively.
    runCommands cmds

runCommands :: forall m message state. Monad m => Array (m message) -> TestMachine m message state Unit
runCommands cmds = for_ cmds \cmd -> message =<< lift cmd

-- | Validates current state of the component under test with the provided
-- | validation function. The function is expected to produce side effects as it
-- | sees fit according to the result of validation. For example, it might call
-- | one of the Test.Spec assertion functions. See example on `runUI`.
assert :: forall m message state
     . Monad m
    => (state -> m Unit) -- ^ Validation function
    -> TestMachine m message state Unit
assert f =
    (lift <<< f) =<< getState

-- | Returns the current state of the component under test.
getState :: forall m message state. Monad m => TestMachine m message state state
getState = gets _.state
