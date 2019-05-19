# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Removed

- `id` from `CommonProps`

### Added

- `Bifunctor`, `Functor`, `Applicative` instances for `Transition`.
- `ComponentReturnCallback` - a CPS-style way of returning polymorphically typed
  components.
- `Elmish.Browser.sandbox` for creating a sandboxed Elmish app.

### Changed

- `construct` and `wrapWithLocalState` now accept a `DispatchMsgFn Unit` instead
  of `(DispatchError -> Effect Unit)` for reporting view errors.
- `construct` now takes the error-reporting function after execution of the
  effect, to improve composability.
- Drop redundant `react*` prefix and match React DOM API naming:
  - Rename and move `Elmish.React.reactMount` to `Elmish.React.DOM.render`
  - Rename and move `Elmish.React.reactUnmount` to
    `Elmish.React.DOM.unmountComponentAtNode`.

### Deprecated

- `pureUpdate` in favor of `pure`.

## 0.0.4

Initial release.
