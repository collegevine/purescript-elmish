---
title: Rendering HTML
nav_order: 4
---

# Rendering HTML
{:.no_toc}

> **Under construction**. This page is unfinished. Many headings just have some
> bullet points sketching the main points that should be discussed.

1. TOC
{:toc}

## HTML elements

Elmish itself is agnostic of how views are actually rendered. It requires you to
produce a `ReactElement` value, and it doesn't care much how you do it. In fact,
in the very early days, all rendering was done in JavaScript, and the resulting
`ReactElement` values were FFIed back to PureScript.

But of course it has to be done _somehow_, and the primary way it is done these
days is with functions provided by [the `purescript-elmish-html`
library](https://github.com/collegevine/purescript-elmish-html). The library
provides a wide array of functions, one for every HTML element. The elements can
be combined in a tree, much like one would do in regular HTML or in React+JSX.

For example:

```haskell
import Elmish.HTML as H

H.div {}
[ H.h1 {} "Welcome!"
, H.p {}
  [ H.text "This is just an example to demonstrate usage of the "
  , H.a { href: "https://github.com/collegevine/purescript-elmish-html" } "elmish-html"
  , H.text " library"
  ]
, H.img { src: "/img/welcome.png", width: 100, height: 200 }
, H.button { onClick: dispatch Login } "Click here to login"
]
```

Most functions have two parameters - HTML attributes and content.

## HTML attributes, aka Props

Every element may have zero or more attributes, which are passed as the first
parameter, typed as a record. The types are constructed so that you can pass
only a subset of all available attributes, not all of that (imagine how
inconvenient that would be!)

The attribute names and types are exactly the same as their namesakes in React.
In fact, the record of attributes is just passed straight to react, without any
further processing. This reduces complexity and saves some performance, but
unfortunately creates some inconvenience with events.

## Content

The "content", or "inside" of the element, can be one of:

* Another element
* An array of elements
* A string

Some elements, such as `img`, do not have a second parameter, because in HTML
they are not allowed to have content.

**NOTE**: Since PureScript doesn't allow arrays of mixed types, strings need
to be wrapped in `H.text` when they are mixed with other elements, as
demonstrated in the example above.
{: .callout }

## Atomic CSS support

If you prefer Bootstrap for styling (or another atomic CSS library), you could
use it exactly the same way you would in React - by passing in a `className`
prop. For example:

```haskell
import Elmish.HTML as H

H.div { className: "border bg-light" }
[ H.p { className: "mt-4 mb-3" } "Click this button:"
, H.button { className: "btn btn-primary px-4", onClick: dispatch ButtonClicked } "Click me!"
]
```

But we found that this quickly becomes quite inconvenient. So the `elmish-html`
library provides an alternative module `Elmish.HTML.Styled`, which exports
alternative versions of all elements taking the CSS class as first parameter:

```haskell
import Elmish.HTML.Styled as H

H.div "border bg-light"
[ H.p "mt-4 mb-3" "Click this button:"
, H.button "btn btn-primary px-4" "Click me!"
]
```

This scheme is somewhat inspired by the [HAML templates](https://haml.info/),
which for the example above would look something like this:

```haml
%div.border.bg-light
  %p.mt-4.mb-3 Click this button:
  %button.btn.btn-primary.px-4 Click me!
```

We find this much more convenient in practice, but of course it's stricly
optional. And you can also mix and match as you wish.

### **Q:** ok, but what if I need to pass other props, besides `className`?
{:.no_toc}

To facilitate this, every element in `Elmish.HTML.Styled` has two versions -
e.g. `button` and `button_` (note the underscore). The former just takes CSS
class as parameter, while the latter also takes other props as a record:

```haskell
import Elmish.HTML.Styled as H

H.div "border bg-light"
[ H.p "mt-4 mb-3" "Click this button:"
, H.button_ "btn btn-primary px-4" { onClick: foo } "Click me!"
]
```

This scheme is used for all elements, even those that don't make sense without
props (such as `img` or `input`), just for consistency and predictability.

## Event handlers

* A work in progress, not good API
* EffectFn1
* <| and <?| helpers
* Use `readForeign` to get at properties
* In extreme cases, use `unsafeCoerce` with care
