---
title: JavaScript interaction
nav_order: 5
---

> **Under construction**. This page is unfinished. Many headings just have some
> bullet points sketching the main points that should be discussed.

# Consuming JS data structures
{:.no_toc}

## Taking JS data as input: `readForeign`

* Often needed, because React and FFI
* But want safety
* But want performance
* So just checking + unsafeCoercing instead of parsing with e.g. Argonaut
* Still returning errors

## Passing data out

* Want to protect from accidentally passing PureScript data
* So have a type-class
* Compile-time only, zero-cost runtime
