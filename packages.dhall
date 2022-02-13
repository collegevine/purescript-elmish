let upstream =
      https://raw.githubusercontent.com/working-group-purescript-es/package-sets/main/packages.dhall
        sha256:f55662cf6cb0bd52a0c1c7e20190ce9b5296269a3abdd244a65cf4428f111d52

in  upstream
  -- `elmish-enzyme` and `elmish-html` are used in integration tests. Because
  -- they both depend on Elmish, we have to remove Elmish from their
  -- dependencies, otherwise Spago will install another copy of Elmish from the
  -- package set, and we'll end up with two copies of Elmish, leading to module
  -- name conflicts during compilation.
  with elmish-enzyme.dependencies = [ "prelude" ]
  with elmish-html.dependencies = [ "prelude", "record" ]
  with metadata.version = "v0.15.0"
