---
title: Using React components
nav_order: 6
---

# Using React components
{:.no_toc}

Because Elmish is just a thin layer on top of React, it is quite easy to use
non-PureScript React components from the wider ecosystem.

A typical import of a React component consists of three parts:

* A row of props, with optional props denoted via `Opt`.
* Actual FFI-import of the component constructor. This import is weakly
  typed and shouldn't be exported from the module. Consider it internal
  implementation detail.
* Strongly-typed, PureScript-friendly function that constructs the
  component. The body of such function usually consists of just a call
  to `createElement` (or `createElement'` for childless components), its
  only purpose being the type signature. This function is what should be
  exported for use by consumers.

Classes and type aliases provided in this module, when applied to the
constructor function, make it possible to pass only partial props to it,
while still ensuring their correct types and presence of non-optional ones.
This is facilitated by the
[undefined-is-not-a-problem](https://github.com/paluh/purescript-undefined-is-not-a-problem/) library.

## Example

### The JSX file with component implementation
```jsx
// `world` prop is required, `hello` and `highlight` are optional
export const MyComponent = ({ hello, world, highlight }) =>
  <div>
    <span>{hello || "Hello"}, </span>
    <span style={ { color: highlight ? "red" : "" } }>{world}</span>
  </div>
```

### PureScript FFI module
```haskell
module MyComponent(Props, myComponent) where

import Data.Undefined.NoProblem (Opt)
import Elmish.React (createElement)
import Elmish.React.Import (ImportedReactComponentConstructor, ImportedReactComponent)

type Props = ( world :: String, hello :: Opt String, highlight :: Opt Boolean )

myComponent :: ImportedReactComponentConstructor Props
myComponent = createElement myComponent_

foreign import myComponent_ :: ImportedReactComponent
```

### PureScript use site
```haskell
import MyComponent (myComponent)
import Elmish.React (fragment) as H

view :: ...
view = H.fragment
  [ myComponent { world: "world" }
  , myComponent { hello: "Goodbye", world: "cruel world!", highlight: true }
  ]
```
