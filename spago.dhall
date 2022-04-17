{ name = "elmish"
, dependencies =
  [ "aff"
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
  , "typelevel-prelude"
  , "unsafe-coerce"
  , "web-dom"
  , "web-html"
  ]
, license = "MIT"
, packages = ./packages.dhall
, repository = "https://github.com/collegevine/purescript-elmish.git"
, sources = [ "src/**/*.purs" ]
}
