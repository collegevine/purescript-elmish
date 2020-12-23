let upstream =
      https://github.com/purescript/package-sets/releases/download/psc-0.13.8-20201222/packages.dhall sha256:620d0e4090cf1216b3bcbe7dd070b981a9f5578c38e810bbd71ece1794bfe13b

let overrides = {=}

let additions = {=}

in  upstream // overrides // additions
