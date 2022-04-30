let conf = ./spago.dhall

in conf // {
  sources = conf.sources # [ "test/**/*.purs" ],
  dependencies = conf.dependencies # [ "aff-promise", "spec", "elmish-enzyme", "elmish-html" ]
}
