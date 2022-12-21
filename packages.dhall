let upstream =
      https://github.com/purescript/package-sets/releases/download/psc-0.15.2-20220613/packages.dhall
        sha256:99f976d547980055179de2245e428f00212e36acd55d74144eab8ad8bf8570d8

in  upstream
  with elmish-testing-library =
    { dependencies = [ "prelude", "aff-promise" ]
    , repo = "https://github.com/collegevine/purescript-elmish-testing-library.git"
    , version = "v0.3.1"
    }
  with elmish-html =
    { dependencies = [ "prelude", "record" ]
    , repo = "https://github.com/collegevine/purescript-elmish-html.git"
    , version = "events"
    }
