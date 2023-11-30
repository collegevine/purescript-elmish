let upstream =
      https://github.com/purescript/package-sets/releases/download/psc-0.15.10-20230719/packages.dhall
        sha256:dfc2383cad9ae1beea830197d36ef39aed9d4cd587c0af04b8fce252209a2f0d

in  upstream
  with elmish-testing-library.dependencies = [ "prelude", "aff-promise" ]
  with elmish-html =
    { dependencies = [ "prelude", "record" ]
    , repo = "https://github.com/collegevine/purescript-elmish-html.git"
    , version = "upgrade-15.13"
    }
