let conf =
      { name = "elmish"
      , dependencies =
        [ "aff"
        , "aff-promise"
        , "argonaut-core"
        , "arrays"
        , "bifunctors"
        , "console"
        , "debug"
        , "effect"
        , "either"
        , "foldable-traversable"
        , "foreign"
        , "foreign-object"
        , "functions"
        , "integers"
        , "js-date"
        , "maybe"
        , "nullable"
        , "partial"
        , "prelude"
        , "refs"
        , "strings"
        , "typelevel-prelude"
        , "unsafe-coerce"
        , "web-dom"
        , "web-html"
        ]
      , license = "MIT"
      , packages = ./packages.dhall // ./packages-test.dhall
      , repository = "https://github.com/collegevine/purescript-elmish.git"
      , sources = [ "src/**/*.purs" ]
      }

in      conf
    //  { sources = conf.sources # [ "test/**/*.purs" ]
        , dependencies =
            conf.dependencies # [ "spec", "elmish-enzyme", "elmish-html" ]
        }
