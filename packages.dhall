let upstream =
      https://github.com/purescript/package-sets/releases/download/psc-0.15.15-20240727/packages.dhall
        sha256:e6e047a89c8a157a733fdbf3a522662dafe90f7101505b593ac6cd1437ad9c06

in  upstream
  with elmish-testing-library.dependencies = [ "prelude", "aff-promise" ]
  with elmish-html =
    { dependencies = [ "prelude", "record" ]
    , repo = "https://github.com/collegevine/purescript-elmish-html.git"
    , version = "v0.9.0"
    }
