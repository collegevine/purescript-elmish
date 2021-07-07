let upstream =
      https://raw.githubusercontent.com/purescript/package-sets/psc-0.14.2/src/packages.dhall sha256:64d7b5a1921e8458589add8a1499a1c82168e726a87fc4f958b3f8760cca2efe

in  upstream
  with debug.version = "v5.0.0"
