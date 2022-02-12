let upstream =
      https://raw.githubusercontent.com/working-group-purescript-es/package-sets/main/packages.dhall
        sha256:da2f9c8eb47408579a5531022f7b3f60127a2fd37749a81c06a51e252f280db0

in  upstream
  with elmish-enzyme =
    { repo =
        "https://github.com/working-group-purescript-es/purescript-elmish-enzyme.git"
    , dependencies = [ "prelude" ]
    , version = "es-modules"
    }
  with elmish-html.dependencies = [ "prelude", "record" ]
  with metadata.version = "v0.15.0"
