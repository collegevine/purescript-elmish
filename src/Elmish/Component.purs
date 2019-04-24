module Elmish.Component
    ( Transition(..)
    , ComponentDef
    , mapCmds, (<$$>)
    , pureUpdate
    , withTrace
    , nat
    , construct
    , wrapWithLocalState
    , ComponentName(..)
    ) where

import Prelude

import Data.Either (Either(..))
import Data.Function.Uncurried (Fn2, runFn2)
import Debug.Trace as Trace
import Effect (Effect, foreachE)
import Effect.Aff (Aff, launchAff_)
import Effect.Class (liftEffect)
import Elmish.Trace (traceTime)
import Elmish.Dispatch (DispatchMsg, DispatchMsgFn(..), DispatchError)
import Elmish.React (ReactComponent, ReactComponentInstance)
import Elmish.React (ReactElement) as React
import Elmish.State (StateStrategy, dedicatedStorage, localState)

-- | A UI component state transition: wraps the new state value together with a
-- | (possibly empty) list of effects that the transition has caused, with each
-- | effect ultimately producing a new message.
data Transition m msg state = Transition state (Array (m msg))

-- | Definition of a component according to The Elm Architecture. Consists of
-- | three functions - init, view, update, - that together describe the
-- | lifecycle of a component.
-- |
-- | Type parameters:
-- |
-- |   * `m` - a monad in which the effects produced by `update` and `init` functions run.
-- |   * `msg` - component's message.
-- |   * `state` - component's state.
type ComponentDef m msg state = {
    init :: Transition m msg state,
    view :: state -> DispatchMsgFn msg -> React.ReactElement,
    update :: state -> msg -> Transition m msg state
}

-- | A nested `map` - useful for mapping over commands in an array: first `map`
-- | maps over the array, second `map` maps over the monad `m`.
-- |
-- | Example:
-- |
-- |      let (Transition subS cmds) = SubComponent.update s.subComponent msg
-- |      in Transition (s { subComponent = subS }) (SubComponentMsg <$$> cmds)
infix 8 mapCmds as <$$>
mapCmds :: forall m msg innerMsg. Functor m => (msg -> innerMsg) -> Array (m msg) -> Array (m innerMsg)
mapCmds mapMsg cmds = map mapMsg <$> cmds

-- | Creates a `Transition` without any commands
pureUpdate :: forall m msg state. state -> Transition m msg state
pureUpdate s = Transition s []

-- | Wraps the given component, intercepts its update cycle, and traces (i.e.
-- | prints to dev console) every command and every state value (as JSON
-- | objects).
withTrace :: forall m msg state
     . Trace.DebugWarning
    => ComponentDef m msg state
    -> ComponentDef m msg state
withTrace def = def { update = tracingUpdate, view = tracingView }
    where
        tracingUpdate s m =
            let (Transition s cmds) = traceTime "Update" \_ -> def.update s $ Trace.spy "Message" m
            in Transition (Trace.spy "State" s) cmds
        tracingView s d =
            traceTime "Rendering" \_ -> def.view s d

-- | Takes a component definition (i.e. init+view+update functions) and
-- | "renders" it as a React DOM element, suitable for passing to
-- | `ReactDOM.render` or embedding in a JSX DOM tree.
bindComponent :: forall msg state
     . BaseComponent                 -- ^ A JS class inheriting from React.Component to serve as base
    -> ComponentDef Aff msg state    -- ^ The component definition
    -> StateStrategy state           -- ^ Strategy of storing state
    -> (DispatchError -> Effect Unit)      -- ^ View error handler
    -> React.ReactElement
bindComponent cmpt def stateStrategy onViewError =
    runFn2 instantiateBaseComponent cmpt { render, componentDidMount: runCmds initialCmds }
    where
        Transition initialState initialCmds = def.init

        {getState, setState} = stateStrategy {initialState}

        render :: ReactComponentInstance -> Effect React.ReactElement
        render component = do
            state <- getState component
            pure $ def.view state (DispatchMsgFn $ dispatchMsg component)

        dispatchMsg :: ReactComponentInstance -> Either DispatchError msg -> DispatchMsg
        dispatchMsg _ (Left err) = onViewError err
        dispatchMsg component (Right msg) = do
            oldState <- getState component
            let Transition newState cmds = def.update oldState msg
            setState component newState $ runCmds cmds component

        runCmds :: Array (Aff msg) -> ReactComponentInstance -> Effect Unit
        runCmds cmds component = foreachE cmds runCmd
            where
                runCmd :: Aff msg -> Effect Unit
                runCmd cmd = launchAff_ $ do
                    msg <- cmd
                    liftEffect $ dispatchMsg component $ Right msg

-- | Given a ComponentDef, binds that def to a freshly created React class,
-- | instantiates that class, and returns the resulting JSX DOM tree.
-- |
-- | Unlike `wrapWithLocalState`, this function uses the bullet-proof strategy
-- | of storing the component state in a dedicated mutable cell, but that
-- | happens at the expense of being effectful.
construct :: forall msg state
     . ComponentDef Aff msg state    -- ^ The component definition
    -> (DispatchError -> Effect Unit)       -- ^ View error handler
    -> Effect React.ReactElement
construct def onViewError = do
    stateStorage <- liftEffect dedicatedStorage
    pure $ withFreshComponent $ \cmpt ->
        bindComponent cmpt def stateStorage onViewError

-- | Monad transformation applied to `ComponentDef`
nat :: forall m n msg state
     . (forall a. m a -> n a)
    -> ComponentDef m msg state
    -> ComponentDef n msg state
nat map def =
    {
        view: def.view,
        init: mapTransition def.init,
        update: \s m -> mapTransition $ def.update s m
    }
    where
        mapTransition (Transition state cmds) = Transition state (map <$> cmds)


-- | Creates a React component that can be bound to a varying ComponentDef,
-- | returns a function that performs the binding.
-- |
-- | Note 1: this function accepts an `Aff`-based ComponentDef, it cannot take
-- | polymorphic or custom monad. The superficial reason for this is that this
-- | function is intended to be used at top-level (see explanation below), where
-- | context for a custom monad is not available. A deeper reason is that this
-- | function creates a self-contained React component, and it is precisely
-- | because it is self-contained that it cannot be seamlessly included in an
-- | outer monadic computation.
-- |
-- | This limitation forces such truly "reusable" components to be written in
-- | terms of `Aff` rather than a custom monad, which is actually a good thing.
-- | However, if it turns out that this component really needs to be in a custom
-- | monad, it is always possible to convert it to `Aff` via the `nat` function.
-- |
-- | Note 2: in order to accomplish this, such aggregated component will store
-- | its state using the React facilities - i.e. via `this.setState` and
-- | `this.state`. While this is appropriate for most cases, it actually has
-- | proven to be fragile in some specific circumstances (e.g. multiple events
-- | occurring within the same JS synchronous frame), so it is not recommended
-- | to use this mechanism for complex components.
-- |
-- | Note 3: this function has to be called exactly once, at top-level. It
-- | cannot be called in the parent's `view` function on every render. Every
-- | time it is called it creates a new React class, so if it was called on
-- | every render, the resulting JSX DOM will contain a new component every
-- | time, which will make React remount that component and destroy its local
-- | state. See explanation on `withCachedComponent` for more.
wrapWithLocalState :: forall msg state args
     . ComponentName
    -> (args -> ComponentDef Aff msg state)
    -> (DispatchError -> Effect Unit)
    -> args
    -> React.ReactElement
wrapWithLocalState name mkDef =
    runFn2 withCachedComponent name $ \cmpt onViewError args ->
        bindComponent cmpt (mkDef args) localState onViewError

-- | A unique name for a component created via `wrapWithLocalState`. These names
-- | don't technically need to be _completely_ unique, but they do need to be
-- | unique enough so that two different `wrapWithLocalState`-created components
-- | that happen to have the same name never replace each other in the DOM. For
-- | this reason, it is recommended to actually make sure these names are
-- | unique, for example by appending a GUID to them. Read on for a more
-- | detailed explanation.
-- |
-- | React uses referential equality to decide whether to create a new instance
-- | of a component (and thus reset its local state) or keep the existing
-- | instance. This means that, on one hand, we cannot use the same React class
-- | for every instantiation, because this may create conflicts, where one
-- | Elmish component replaces another in the DOM, but they look like the same
-- | component to React, which makes it reuse state, which leads to chaos. On
-- | the other hand, we cannot create a fresh class on every render, because
-- | then React will see it as a new component every time, and will reset its
-- | state every time.
-- |
-- | This means that we need some way of figuring out whether it needs to be
-- | logically "same" component or "different", but there is no way to get that
-- | "for free" (same way React gets it for free from referential equality) due
-- | to PureScript's purity. Therefore, the only reliable way is to ask the
-- | programmer, which is accomplished by requiring a `ComponentName`, which
-- | serves as a key.
newtype ComponentName = ComponentName String

--
--
--

-- Props for the React component that is used as base for this framework. The
-- component itself is defined in `./ComponentClass.js`
type BaseComponentProps = {
    render :: ReactComponentInstance -> Effect React.ReactElement,
    componentDidMount :: ReactComponentInstance -> Effect Unit
}

type BaseComponent = ReactComponent BaseComponentProps

-- This is just a call to `React.createElement`, but we can't use the
-- general-purpose `createElement` function from `./React.purs`, because it
-- requires that the props type be "plain JavaScript" (i.e. have a
-- CanPassToJavaScript instance), and these props here are not that. It would be
-- possible to make this type passable to JS by using `Foreign` and maybe even
-- `unsafeCoerce` in places, but I have decided it wasn't worth it, because this
-- is just one place at the core of the framework.
foreign import instantiateBaseComponent :: Fn2 BaseComponent BaseComponentProps React.ReactElement

-- | On first call with a given name, this function returns a fresh React class.
-- | On subsequent calls with the same name, it returns the same class. It has
-- | this weird CPS signature in order to prevent PureScript from optimizing out
-- | repeated calls.
--
-- This is essentially a hack, but not quite. It operates in the grey area
-- between PureScript and JavaScript. See comments on `ComponentName` for a more
-- detailed explanation.
foreign import withCachedComponent :: forall a. Fn2 ComponentName (BaseComponent -> a) a

-- | Creates a fresh React component on every call. This is similar to
-- | `withCachedComponent`, but without the cache - creates a new component
-- | every time.
foreign import withFreshComponent :: forall a. (BaseComponent -> a) -> a
