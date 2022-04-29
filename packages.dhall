let upstream =
      https://github.com/purescript/package-sets/releases/download/psc-0.15.0-20220429/packages.dhall
        sha256:03c682bff56fc8f9d8c495ffcc6f524cbd3c89fe04778f965265c08757de8c9d

in  upstream
  with elmish-enzyme =
    { dependencies = [ "prelude" ]
    , repo =
        "https://github.com/working-group-purescript-es/purescript-elmish-enzyme.git"
    , version = "es-modules"
    }
  with elmish-html =
    { dependencies = [ "prelude", "record" ]
    , repo = "https://github.com/collegevine/purescript-elmish-html.git"
    , version = "v0.6.0"
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
