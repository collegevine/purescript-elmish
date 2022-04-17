let upstream =
      https://raw.githubusercontent.com/purescript/package-sets/prepare-0.15/src/packages.dhall
        sha256:b1c6d06132b7cbf1e93b1e5343044fba1604b50bfbe02d8f80a3002e71569c59

in  upstream
  with elmish-enzyme =
    { dependencies = [ "prelude" ]
    , repo = "https://github.com/collegevine/purescript-elmish-html.git"
    , version = "master"
    }
  with elmish-html =
    { dependencies = [ "prelude", "record" ]
    , repo =
        "https://github.com/working-group-purescript-es/purescript-elmish-enzyme.git"
    , version = "es-modules"
    }
  with debug =
    { dependencies = [ "prelude", "functions" ]
    , repo = "https://github.com/working-group-purescript-es/purescript-debug.git"
    , version = "es-modules"
    }
  with spec = {
    repo = "https://github.com/purescript-spec/purescript-spec.git"
  , version = "master"
  , dependencies
       =
    [ "aff"
    , "ansi"
    , "avar"
    , "console"
    , "exceptions"
    , "foldable-traversable"
    , "fork"
    , "now"
    , "pipes"
    , "prelude"
    , "strings"
    , "transformers"
    ]
  }
  with metadata.version = "v0.15.0-alpha-05"
