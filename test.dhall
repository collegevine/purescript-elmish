let conf = ./spago.dhall

in conf // {
  sources = conf.sources # [ "test/**/*.purs" ],
  dependencies = conf.dependencies # [ "avar", "spec", "elmish-testing-library", "elmish-html" ]
}
