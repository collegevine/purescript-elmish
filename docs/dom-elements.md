---
title: Rendering HTML
nav_order: 4
---

# Rendering HTML
{:.no_toc}

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

view =
  H.div {}
  [ H.h1 {} "Welcome!"
  , H.p {}
    [ H.text "This is just an example to demonstrate usage of the "
    , H.a { href: "https://github.com/collegevine/purescript-elmish-html" } "elmish-html"
    , H.text " library"
    ]
  , H.img { src: "/img/welcome.png", width: 100, height: 200 }
  , H.button { onClick: H.handle \_ -> dispatch Login } "Click here to login"
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

view =
  H.div { className: "border bg-light" }
  [ H.p { className: "mt-4 mb-3" } "Click this button:"
  , H.button { className: "btn btn-primary px-4", onClick: H.handle \_ -> dispatch ButtonClicked } "Click me!"
  ]
```

But we found that this quickly becomes quite inconvenient. So the `elmish-html`
library provides an alternative module `Elmish.HTML.Styled`, which exports
alternative versions of all elements taking the CSS class as first parameter:

```haskell
import Elmish.HTML.Styled as H

view =
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

view =
  H.div "border bg-light"
  [ H.p "mt-4 mb-3" "Click this button:"
  , H.button_ "btn btn-primary px-4" { onClick: ... } "Click me!"
  ]
```

This scheme is used for all elements, even those that don't make sense without
props (such as `img` or `input`), just for consistency and predictability.

## Event handlers

Since the props record is passed directly to React, and in React event handlers
are modeled as functions taking
[`SyntheticEvent`](https://reactjs.org/docs/events.html), the `elmish-html`
library simply directly maps that to PureScript:

```haskell
onClick :: EventHandler SyntheticEvent
```

`EventHandler` is conceptually a JavaScript function taking one parameter, so
that it can be passed directly to React and understood. But in PureScript it's
an opaque type (i.e. with hidden constructor). Values of this type can be
created with the `handle` function.

The `SyntheticEvent` type is a `newtype` wrapping a record that directly
represents React's `SyntheticEvent` as [described in its
docs](https://reactjs.org/docs/events.html). To access the properties you can
match on its constructor like this:

```haskell
import Elmish.HTML.Events as E

data Message = ... | ButtonClicked { when :: Number } | ...

H.button_ "btn btn-primary"
  { onClick: H.handle \(E.SyntheticEvent e) -> dispatch $ ButtonClicked { when: e.timestamp }
  }
  "Click me!"
```

The `handle` function takes care of creating an `EventHandler` from a PureScript
function `event -> Effect Unit`.

If you don't need to examine the event object (often happens with `onClick`
events), just use underscore for parameter name:

```haskell
  { onClick: H.handle \_ -> dispatch ButtonClicked
  }
```

Some events will have a different type of event object. For example, mouse
events will have `MouseEvent` and keyboard events will have `KeyboardEvent`.
Their respective properties can be accessed by matching on their constructors in
the same way:

```haskell
H.div_ ""
  { onMouseMove: H.handle \(E.MouseMove e) -> dispatch $ MouseMoved { x: e.pageX, y: e.pageY }
  , onKeyPress: H.handle \(E.KeyboardEvent e) -> when (e.key == "Enter") $ dispatch EnterPressed
  }
```

## Accessing input value

Some events, such as `input.onChange`, require accessing the
`event.target.value` property to get the new value of the input. While it is
possible to get the `event.target` property (of type `Web.DOM.Element`), cast it
to `HTMLInputElement`, and then call [the `value`
function](https://pursuit.purescript.org/packages/purescript-web-html/4.1.0/docs/Web.HTML.HTMLInputElement#v:value)
on it, that's a lot of ceremony for such a frequent operation. To reduce the
friction, the `elmish-html` library provides a convenience function `inputText`,
which does all of that in one go:

```haskell
H.input_ ""
  { value: ...
  , onChange: H.handle \e -> dispatch $ InputChanged (E.inputText e)
  }
```

Note that the `inputText` function will not work on just any event of any tag,
it only applies specifically to `input.onChange`. To guarantee this, the
`input.onChage` event has a special event object type - `InputChangeEvent`, and
the `inputText` function requires a parameter of that type.

Similar convenience functions are available for other frequently occurring situations, including:

* `inputChecked` - returns the `checked` property of an `<input type=checkbox>`
  element. Applies only to `input.onChange` event.
* `textareaText` - value of a `<textarea>` element. Applies only to
  `textarea.onChange` event.
* `selectSelectedValue` - selected value of a `<select>` element. Applies only
  to `select.onChange` event.

## Lower-level event access

In extreme cases it may be necessary to perform side effects other than
dispatching a message. Examples may include `stopPropagation`, `preventDefault`,
or dispatching multiple messages (a discouraged practice, but sometimes
necessary nevetherless).

This can be achieved trivially via the `do` notation (or your favourite way of
combining effects):

```haskell
H.button_ ""
  { onClick: H.handle \e -> do
      E.preventDefault e
      E.stopPropagation e
      dispatch ButtonClicked
  }
  "Click me!"

H.input_ ""
  { onChange: H.handle \e -> do
      dispatch $ InputChanged (E.inputText e)
      dispatch ResetSomething
  }

H.div_ ""
  { onClick: H.handle \_ -> do
      window >>= location >>= setHash "foo"
      dispatch NavigatedToHashFoo
  }
```
