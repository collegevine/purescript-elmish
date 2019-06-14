{-
This file is intended to be included by other projects in order to include
Elmish in their Dahl package set.

For example:

    let upstream =
          https://raw.githubusercontent.com/purescript/package-sets/psc-0.13.0-20190611/src/packages.dhall sha256:8ef3a6d6d123e05933997426da68ef07289e1cbbdd2a844b5d10c9159deef65a

    let elmish =
          https://raw.githubusercontent.com/collegevine/purescript-elmish/master/elmish.dhall

    let additions = {
      elmish = elmish "v0.1.0"
    }

    in  upstream // additions

-}

let mkPackage =
      https://raw.githubusercontent.com/purescript/package-sets/psc-0.13.0-20190611/src/mkPackage.dhall sha256:0b197efa1d397ace6eb46b243ff2d73a3da5638d8d0ac8473e8e4a8fc528cf57

in
      mkPackage
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
        "https://github.com/collegevine/purescript-elmish.git"
        {- Version is intentionally left out for the consumer to specify -}
