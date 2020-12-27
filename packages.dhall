let upstream =
      https://raw.githubusercontent.com/purescript/package-sets/prepare-0.14/src/packages.dhall sha256:2c0a5af7ed5158218e0068f2328101fd9f0461e17ea37298e5af6875a96f34ac

let overrides =
      { newtype = upstream.newtype with dependencies = [ "prelude", "safe-coerce" ]
      }

let additions =
      { safe-coerce =
        { dependencies = [ "unsafe-coerce" ]
        , repo = "https://github.com/purescript/purescript-safe-coerce.git"
        , version = "master"
        }
      }

in  upstream // overrides // additions
