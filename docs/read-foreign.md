---
title: Consuming JS data
nav_order: 5
---

> **Under construction**. This page is unfinished. Many headings just have some
> bullet points sketching the main points that should be discussed.

# Consuming JS data
{:.no_toc}

Elmish is explicitly built on top of React and does not try to hide this fact
behind a higher-level abstraction. Elmish embraces React. This lets us leverage
the ecosystem, but also comes with certain difficulties as we're forced to pass
data to and from JavaScript code, and JavaScript code can be very liberal with
data shapes.

To make this data exchange saner and safer, Elmish provides a mechanism for data
shape validation.

## Taking JS data as input

If you're looking at a data structure you just got from some JavaScript code,
represented as a `Foreign` of course (can't make assumptions, can we?), you can
use the `readForeign` function to see if it has the right shape:

```haskell
import Elmish.Foreign (readForeign)

type MyData = { x :: { y :: Int }, z :: String }

callMeFromJavaScript :: Foreign -> String
callMeFromJavaScript f =
  case readForeign f :: Maybe MyData of
    Nothing -> "Incoming data has the wrong shape"
    Just a -> "Got the right data: x.y = " <> show a.x.y <> ", z = " <> a.z
```

`readForeign` will return `Nothing` if the value doesn't conform to the expected
type, or `Just a` if it does, where `a` has the right type.

**NOTE** `readForeign` doesn't actually _convert_ the data structure. It only
traverses it and makes sure that it has the right shape.
{: .callout }

This strategy turns out to be orders of magnitude faster than parsing with
something like `purescript-argonaut`, which lets use it at all kinds of ingest
boundaries, such as:

* Network API calls
* Top-level entry points
* Event handlers
* etc.

The example above uses the `readForeign` function, which returns a `Maybe`, but
it also has a big brother `readForeign'` (note the prime), which returns an
`Either`, providing an error message about what exactly is incorrect with the
data:

```haskell
callMeFromJavaScript :: Foreign -> String
callMeFromJavaScript f =
  case readForeign' f :: _ _ MyData of
    Left err -> "Oops: " <> err
    Right a -> "Got the right data: x.y = " <> show a.x.y <> ", z = " <> a.z
```

**NOTE**: We're using type wildcards (underscores) so we don't have to write
`Either String` every time.

## Primitive types only

The fact that `readForeign` doesn't actually convert data has an important
corollary: the data structure cannot contain any types that do not have
straightforward JavaScript representation.

For example, `String` is fine, and so it `Array String`, but `Maybe String` is
not allowed, and neither is `Either String Int`.

This is by design. The idea behind this mechanism is to enable _type safety_,
which is not the same as _data marshalling_, although the two are frequently
conflated. In any given situation marshalling may or may not be appropriate. If
it is, it can be done separately, in combination with `readForeign` or instead
of it. If no marshalling is required, `readForeign` is much smaller and more
performant.

## Passing data out

* Want to protect from accidentally passing PureScript data
* So have a type-class
* Compile-time only, zero-cost runtime
