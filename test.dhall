let conf = ./spago.dhall

in conf // {
  sources = conf.sources # [ "test/**/*.purs" ],
  dependencies = conf.dependencies # [ "avar", "now", "spec", "elmish-testing-library", "elmish-html" ]
}
