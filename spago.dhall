{-
Welcome to a Spago project!
You can edit this file as you like.
-}
{ name = "elmish"
, dependencies =
  [ "aff"
  , "argonaut-core"
  , "console"
  , "debug"
  , "effect"
  , "either"
  , "foreign-object"
  , "functions"
  , "maybe"
  , "prelude"
  , "psci-support"
  , "record"
  , "tuples"
  , "typelevel-prelude"
  , "web-html"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
