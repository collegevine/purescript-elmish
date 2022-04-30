let upstream =
      https://github.com/purescript/package-sets/releases/download/psc-0.15.0/packages.dhall
        sha256:8734be21e7049edeb49cc599e968e965442dad70e3e3c65a5c2d1069ec781d02

in  upstream
  with elmish-enzyme =
    { dependencies = [ "prelude", "aff-promise" ]
    , repo = "https://github.com/collegevine/purescript-elmish-enzyme.git"
    , version = "v0.1.0"
    }
  with elmish-html =
    { dependencies = [ "prelude", "record" ]
    , repo = "https://github.com/collegevine/purescript-elmish-html.git"
    , version = "v0.7.0"
    }
  with debug =
    { dependencies = [ "prelude", "functions" ]
    , repo =
        "https://github.com/working-group-purescript-es/purescript-debug.git"
    , version = "es-modules"
    }
  with undefined-is-not-a-problem =
    { repo =
        "https://github.com/working-group-purescript-es/purescript-undefined-is-not-a-problem.git"
    , version = "v0.15.0-update"
    , dependencies =
      [ "assert"
      , "effect"
      , "either"
      , "foreign"
      , "maybe"
      , "prelude"
      , "random"
      , "tuples"
      , "unsafe-coerce"
      ]
    }
