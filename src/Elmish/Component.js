const React = require("react")
const component = require("Elmish/ComponentClass")

exports.withCachedComponent = (function() {
  const cache = {}

  return function(name, f) {
    const c = cache[name] || (cache[name] = component.mkFreshComponent())
    return f(c)
  }
})()

exports.withFreshComponent = function(f) {
  return f(component.mkFreshComponent())
}

exports.instantiateBaseComponent = React.createElement
