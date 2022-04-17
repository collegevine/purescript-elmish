let upstream =
      https://raw.githubusercontent.com/purescript/package-sets/psc-0.14.5-20220102/src/packages.dhall sha256:17ca27f650e91813019dd8c21595b3057d6f4986118d22205bdc7d6ed1ca28e8

in  upstream
  -- `elmish-enzyme` and `elmish-html` are used in integration tests. Because
  -- they both depend on Elmish, we have to remove Elmish from their
  -- dependencies, otherwise Spago will install another copy of Elmish from the
  -- package set, and we'll end up with two copies of Elmish, leading to module
  -- name conflicts during compilation.
  with elmish-enzyme.dependencies = [ "prelude" ]
  with elmish-enzyme.version = "v0.0.2"
  with elmish-html.dependencies = [ "prelude", "record" ]
  with elmish-html.version = "opt"
