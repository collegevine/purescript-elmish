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

**NOTE**: the way DOM events are modeled in the `elmish-html` library is a work
in progress. The API is functional, but not very ergonomic. It is subject to
change in the future.
{: .callout }

Since the props record is passed directly to React, and in React event handlers
are modeled as functions taking [Synthetic
Event](https://reactjs.org/docs/events.html), the `elmish-html` library simply
directly maps that to PureScript:

```haskell
onChange :: EffectFn1 Foreign Unit
```

We represent the Synthetic Event argument as `Foreign` in order to avoid taking
`purescript-web-events` (or any other similar library) as a dependency. Our
experience shows that well-typed `Event` functions are not actually useful in
practice.

A notable exception is the `onClick` event, which is represented as just:

```haskell
onClick :: Effect Unit
```

We chose to ignore the argument in this particular case because it's very rarely
useful in practice and most of the time ends up being ignored.

### **Q:** but if the event is just `Foreign`, how do I get at its properties?
{: .no_toc }

To do this, Elmish provides a universal way to access JavaScript data in a safe
way: `readForeign`. Given expected shape of the `Foreign` object, this function
can verify that the object indeed has that shape, and return it correctly typed:

```haskell
view :: State -> Dispatch Message -> ReactElement
view state dispatch =
  ...
  H.input_
    { type: "text"
    , value: state.inputValue
    , onChange: mkEffectFn1 \foreignEvent -> do
        let event :: Maybe { target :: { value :: String } } = readForeign foreignEvent
        case event of
          Just e -> dispatch $ InputChanged e.target.value
          Noting -> pure unit -- Event did not have expected fields for some reason
    }
  ...
```

Here we are specifying the expected type of `event` variable, which is
`readForeign`'s result, and if it ends up as `Just`, we can be sure the event
has the specified shape. Then we can just access its properties -
`e.target.value`.

But of course, this is a lot of boilerplate: the `mkEffectFn1` call, the `case`
expression - all of that would be exactly the same for every event handler. So
Elmish provides two operators for convenience: `<|` and `<?|`

The `<|` operator takes care of the `EffectFn1` business. It takes the
`dispatch` function on the left and an `event -> message` function on the right,
and takes care of piping through from one to the other:

```haskell
  , onChange: dispatch <| \event -> InputChanged "foo"
```

The `<?|` operator does basically the same thing, except the function it takes
on the right is `event -> Maybe message`:

```haskell
  , onChange: dispatch <?| \event -> do
      e :: { target :: { value :: _ } } <- readForeign event
      Just $ InputChanged e.target.value
```

**NOTE**: Here we're taking advantage of "type wildcards" - replacing `String`
with an underscore means asking PureScript to infer it from context, which it
can do from the type of `InputChanged`'s argument. Sadly, there seems to be no
way to infer the whole shape of the nested records.
{: .callout }

In real applications that work a lot with textboxes, we usually end up defining
a special-purpose function for accessing `event.target.value`:

```haskell
eventTargetValue :: Foreign -> Maybe String
eventTargetValue f =
  e :: { target :: { value :: _ } } <- readForeign f
  Just e.target.value

...

    , onChange: dispatch <?| \e -> InputChanged <$> eventTargetValue e

...
```

Though this function is not (yet?) part of the library.

## Lower-level event access

In extreme cases it may be necessary to access the React Synthetic Event after
all, even when it's not part of the event's type signature (such as `onClick`),
for example to `preventDefault` or `stopPropagation`.

For these cases there is currently no good solution, and we're simply resorting
to `unsafeCoerce`ing our way through it:

```haskell
  ...
  , onClick: unsafeCoerce $ mkEffectFn1 \e -> do
      stopPropagation e
      dispatch ButtonClicked
  ...
```

If you find yourself in need to do this, use care and make sure you understand
underlying JavaScript types.
