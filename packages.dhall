let upstream =
      https://raw.githubusercontent.com/working-group-purescript-es/package-sets/main/packages.dhall
        sha256:f55662cf6cb0bd52a0c1c7e20190ce9b5296269a3abdd244a65cf4428f111d52

in  upstream
  with metadata.version = "v0.15.0"
