---
title: Intro
nav_order: 0
---

# Intro
{:.no_toc}

Elmish is a PureScript UI library that (loosely) follows [The Elm
Architecture](https://guide.elm-lang.org/architecture/), implemented as a
thin layer on top of React. Unlike Elm itself, Elmish allows arbitrary
side-effects, including running them in a custom monad.

## The Elm Architecture

In short, the idea is that your UI consists of:

* "state" - a data structure that describes what the UI looks like and what it
  can do.
* "view" - a function that can take the "state" and produce some HTML from it.
* "message" - a description of something happening in the UI, such as a button
  click or a timer firing. There is generally a finite set of possible messages
  for a given UI component.
* "update" - a function that can take the current "state" and a "message", and
  figure out what the new state should be as a result of receiving that message.
* "init" - a way to create initial "state".

![Flow Diagram]({% link diagram.png %})

## A small, yet complete example

Some more involved examples can be found in the
[elmish-examples](https://github.com/collegevine/purescript-elmish-examples)
repository.

This example is just to give the overall feel of what an Elmish UI generally
looks like, and to tie together the above bullet-list definition. For more
explanations and tutorials, see [Getting Started]({% link getting-started.md %}).

```haskell
type Cell = { x :: Int, y :: Int }
type State = Array Cell
data Message = Up | Down | Left | Right

bounds :: Cell
bounds = { x: 20, y: 20 }

init :: Transition Aff Message State
init = pure $ (5..10) <#> \idx -> { x: idx, y: 10 }

view :: State -> Dispatch Message -> ReactElement
view state dispatch =
  H.div "m-4"
  [ H.div "d-flex flex-column mb-3" $ 0..(bounds.y-1) <#> \row ->
      H.div "d-flex" $ 0..(bounds.x-1) <#> \col ->
        H.div_ "border border-dark p-2 m-1" { style: H.css { background: bgColor col row } } ""
  , H.button_ "btn btn-outline-primary ml-5 mr-2" { onClick: H.handle \_ -> dispatch Left } "⬅️"
  , H.button_ "btn btn-outline-primary mr-2" { onClick: H.handle \_ -> dispatch Down } "⬇️"
  , H.button_ "btn btn-outline-primary mr-2" { onClick: H.handle \_ -> dispatch Up } "⬆️"
  , H.button_ "btn btn-outline-primary mr-2" { onClick: H.handle \_ -> dispatch Right } "➡️"
  ]
  where
    bgColor x y = case findIndex (eq { x, y }) state of
      Just idx -> "rgb(255, " <> show (idx*45) <> ", 255)"
      Nothing -> "white"

update :: State -> Message -> Transition Aff Message State
update state msg = case msg of
  Up -> move 0 (-1)
  Down -> move 0 1
  Left -> move (-1) 0
  Right -> move 1 0
  where
    move dx dy = case uncons state of
      Just { head } -> do
        pure $ { x: head.x + dx, y: head.y + dy } : take (length state - 1) state
      Nothing ->
        pure state
```

![Example]({% link example.gif %})
