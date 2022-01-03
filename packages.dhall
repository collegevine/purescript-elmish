let upstream =
      https://raw.githubusercontent.com/purescript/package-sets/psc-0.14.5-20220102/src/packages.dhall sha256:17ca27f650e91813019dd8c21595b3057d6f4986118d22205bdc7d6ed1ca28e8

in  upstream
  with elmish-enzyme.dependencies = [ "prelude" ]
  with elmish-enzyme.version = "v0.0.2"
  with elmish-html.dependencies = [ "prelude", "record" ]
