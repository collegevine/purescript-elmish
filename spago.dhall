{ name = "elmish"
, dependencies =
    [ "aff"
    , "argonaut-core"
    , "console"
    , "debug"
    , "either"
    , "foreign-object"
    , "functions"
    , "maybe"
    , "prelude"
    , "record"
    , "tuples"
    , "typelevel-prelude"
    , "web-html"
    ]
, license = "MIT"
, packages = ./packages.dhall
, repository = "https://github.com/collegevine/purescript-elmish.git"
, sources = [ "src/**/*.purs" ]
}
