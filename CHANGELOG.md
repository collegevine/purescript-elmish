# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.12.0

### Changed

- Fixed a bug that allowed `ComponentDef` to be captured in closures for a long
  time, which could lead to using stale values in complex scenarios where
  `ComponentDef` is not constant, but depends on arguments. #83

- **Breaking**: Change the order of arguments of `bindComponent`

## 0.11.4

### Added

- `quasiBind`, `hush`, and `subscribe'` functions for subscriptions to enable
  creating more complicated subscriptions from primitive ones.

## 0.11.1

### Changed

- it is no longer possible to dispatch messages after unmounting.

## 0.11.0

### Added

- support for subscriptions - see the `Elmish.Subscription` module.

### Changed

- **Breaking**: `forks`'s parameter now takes a record of `{ dispatch, onStop }`
  instead of just a naked `dispatch` function. This change is in support of
  subscriptions.

## 0.10.1

### Changed

- Upgraded to PureScript 0.15.13
- **Breaking**: `CanReceiveFromJavaScript.validateForeignType` method no longer
  takes a `Proxy` as first parameter, relying instead on visible type
  applications.

## 0.10.0

### Changed

- type parameters of `readForeign` and `readForeign'` can now be specified via
  visible type application, a new feature in PureScript 0.15.10

## 0.9.3

### Changed

- `handleMaybe` now forces `Maybe`, allowing use of ambiguous functors, e.g.
  `onClick: dispatch <?| pure Foo`

## 0.9.2

### Changed

- Operators `<|` and `<?|` now have zero precedence, allowing mixing them with
  the `$` operator, e.g. `dispatch <| foo $ bar $ baz`

## 0.9.0

### Added

- `handleEffect` overloaded function for more ergonomic construction of event
  handlers.

### Changed

- Operators `<|` and `<?|` (functions `handle` and `handleMaybe`) can now take
  either a "message" or a function "event -> message" as their right argument
  for more ergonomic construction of event handlers.

## 0.8.2

### Changed

- `Data.Undefined.NoProblem.Req` is now considered safe for passing to/from JS

## 0.8.0

### Changed

- Upgraded to PureScript 0.15

## 0.7.0

### Added

- `Elmish.React.Ref` type with a `callbackRef` constructor

### Changed

- **Breaking**: Renamed `Elmish.Ref` to `Elmish.Opaque`
- **Breaking**: changed the FFI mechanism to use `Opt` to denote optional props
  instead of two separate rows.

## 0.6.0

### Removed

- **Breaking**: Removed the whole `Elmish.JsCallback` module. All use sites
  should convert to `EffectFnN`.

## 0.5.8

### Changed

- React props for FFI-imported components are now allowed to have a `ref` prop.
  This was a silly restriction.
- Generated React component classes now have more descriptive names. This is to
  help with debugging and testing. See
  [#52](https://github.com/collegevine/purescript-elmish/pull/52).

## 0.5.7

### Changed

- Fixed a bug related to maintaining state in `wrapWithLocalState`. See [#50](https://github.com/collegevine/purescript-elmish/pull/50).

### Added

- Integration tests powered by [enzyme](https://enzymejs.github.io/enzyme/)

## 0.5.6

### Changed

- **Breaking**: `ComponentDef` renamed to `ComponentDef'`.
- Added `ComponentDef` as type alias for `ComponentDef' Aff`.
- **Breaking**: `Transition` renamed to `Transition'`.
- Added `Transition` as type alias for `Transition' Aff`.

## 0.5.5

### Changed

- Fixed a bug with `CanReceiveFromJavaScript (Array Foreign)` instance: it had a
  superfluous constraint.

## 0.5.4

### Added

- `CanReceiveFromJavaScript (Object a)` instance for any `a`. Previously only
  worked for `Foreign`.
- `CanReceiveFromJavaScript (Array Foreign)` instance as an optimization. Unlke
  the general `Array a` instance, the `Array Foreign` instance doesn't have to
  check every element of the array.

## 0.5.3

### Added

- `readForeign'` - a new function that's like `readForeign`, but returns error
  information on failure.
- Added tests. So far - only for `readForeign`.

### Changed

- **Breaking**: `CanReceiveFromJavaScript` class modified to afford that.

## 0.5.2

### Changed

- Bug fix: `readForeign` for records no longer requires nullable fields to be
  present in the record.

## 0.5.1

### Changed

- Package maintenance

## 0.5.0

### Removed

- **Breaking**: `DispatchMsgFn` (replaced with `Dispatch`) and friends -
  `issueMsg`, `issueError`, `cmapMaybe`, `dispatchMsgFn`, `ignoreMsg`.
- **Breaking**: Dispatch can no longer report errors due to failed decoding of
  parameters passed from JavaScript. This feature turned out to be nearly
  useless, yet it was creating quite a bit of extra complexity.

### Changed

- **Breaking**: `handle` and `handleMaybe` are no longer variadic. They only
  work with single-argument event handler, which is the most common case. Since
  `Dispatch` is now just a function, other cases can be easily covered via
  `mkEffectFnX` (for which both `handle` and `handleMaybe` are no facades).

### Added

- **Breaking**: `Dispatch` (replaces `DispatchMsgFn`) - just an alias for `msg -> Effect Unit` now
- `<|` alias for `handle`
- `<?|` alias for `handleMaybe`
- `CanPassToJavaScript` instances for `Effect Unit`, `EffectFn1 a Unit`, and
  `EffectFn2 a b Unit`, so they can be used as event handlers.

## 0.4.0

### Changed

- migrated to PureScript 0.14

## 0.3.2

### Changed

- `Transition` is now a `Monad`

## 0.3.1

### Changed

- migrated to GitHub Actions

## 0.3.0

### Changed

- migrated to Spago

## 0.2.2

### Changed

- we now make sure that commands (aka effects) yielded by an `update` call
  actually run asynchronously

## 0.2.1

### Added

- `defaultMain` - a convenience entry point for the simplest use case - a single
  bundle embedded in a single HTML file.

## 0.2.0

### Changed

- **Breaking**: The signature of `Transition` now allows effects to produce
  zero, one, or multiple messages, instead of exactly one as before. This is
  achieved by making each effect take a message-dispatching callback rather than
  monadically returning a message as before.
- **Breaking**: `fork` now requires `MonadEffect`.

### Added

- Convenience smart constructor `transition`, which has the same signature as
  the `Transition` data constructor used to have before this change.
- `forks` - like `fork` (see v0.1.4), but allows the effect to produce zero,
  one, or multiple messages by way of taking a callback rather than returning a
  message.
- `forkVoid` - like `fork`, but the effect does not produce any messages.
- `forkMaybe` - like `fork`, but the effect may or may not produce a message.

### Removed

- **Breaking**: removed the `Elmish.Test` module. Now that the type of
  `Transition` no longer pretends to be pure (i.e. contains mention of
  `Effect`), the testing support can no longer work in the pure `StateT`, and
  will have to be rewritten on top of `Effect`, with a mutable cell to
  accumulate messages. However, since we're not actually using testing support
  (yet?), I have decided to deprioritize this.

## 0.1.6

### Added

- Support for SSR (server-side rendering) via `Elmish.Boot.boot`. This breaks
  pre-existing `Elmish.Boot` users (see "Removed").

### Removed

- **Breaking**: The contents of `Elmish.Boot` - `BootResult`, `boot`, and
  `boot'`. Replaced and subsumed by server-side rendering support (see "Added").

### Changed

- **Breaking**: `Elmish.React.reactMount` renamed to `render` to match React's
  naming.
- `wrapWithLocalState` will now report errors to the console instead of
  swallowing them. This could be used by catch-all error reporters such as
  Rollbar or Airbrake.
- **Breaking**: `mkJsCallback` remaned to `jsCallback` and lost its `onError`
  parameter. It will now report errors to the console, same as
  `wrapWithLocalState`. The previous version with an explicit `onError`
  parameter is now available as `jsCallback'`
- React API is now FFIed via `EffectFnX` instead of `FnX`.

## 0.1.5

### Changed

- **Breaking**: `wrapWithLocalState` no longer takes an extra
  `DispatchMsgFn Unit` parameter (used only for error reporting)
- **Breaking**: All places that previously took a `DispatchMsgFn Unit` sink for
  the purpose of reporting errors only, now take a `DispatchMsgFn Void` instead
  to better reflect the fact that they're not going to issue messages through
  that sink
- Upgraded to PureScript 0.13.8

### Added

- `wrapWithLocalState'` - a more elaborate version of `wrapWithLocalState` that
  takes the extra `DispatchMsgFn Void` parameter

## 0.1.4

### Added

- `Bind` instance for `Transition`, enabling `do`-notation
- `fork` - a convenience wrapper function for constructing effectful state
  updates in imperative-ish style
- Reexports `lmap` and `rmap` from `BiFunctor`

## 0.1.3

### Added

- Convenience reexports of `bimap`, `(>$<)`, and `(>#<)`

## 0.1.2

### Added

- Support HTML data attributes via `_data :: Object` API.

## 0.1.0

### Changed

- Upgraded to PureScript 0.13.0 (see [release notes](https://github.com/purescript/purescript/releases/tag/v0.13.0))

## 0.0.5

### Removed

- `id` from `CommonProps`

### Added

- `Bifunctor`, `Functor`, `Applicative` instances for `Transition`
- `ComponentReturnCallback` - a CPS-style way of returning polymorphically typed
  components.
- `boot` - a common-case app entry point: mounts a UI component to a DOM element
  with given ID.

### Changed

- `construct` and `wrapWithLocalState` now accept a `DispatchMsgFn Unit` instead
  of `(DispatchError -> Effect Unit)` for reporting view errors.
- `construct` now takes the error-reporting function after execution of the
  effect, to improve composability.

### Deprecated

- `pureUpdate` in favor of `pure`

## 0.0.4

Initial release
