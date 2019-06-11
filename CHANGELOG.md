# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.1.0

### Changed

- Upgraded to PureScript 0.13.0 (see [release noted](https://github.com/purescript/purescript/releases/tag/v0.13.0))

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
