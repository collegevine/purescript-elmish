let upstream =
      https://raw.githubusercontent.com/purescript/package-sets/psc-0.14.4/src/packages.dhall sha256:eee0765aa98e0da8fc414768870ad588e7cada060f9f7c23c37385c169f74d9f

in  upstream

      -- NOTE: We have to remove Elmish itself from dependencies, otherwise
      -- Spago will install another copy of Elmish from the package set, and
      -- we'll end up with two copies of Elmish, leading to module name
      -- conflicts during compilation.
      with elmish-enzyme = {
            dependencies = ["prelude"],
            repo = "https://github.com/collegevine/purescript-elmish-enzyme.git",
            version = "main"
      }
      with elmish-html.dependencies = ["prelude", "record"]
