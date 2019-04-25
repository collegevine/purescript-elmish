const React = require("react")

exports.withCachedComponent = (function() {
  const cache = {}

  return function(name, f) {
    const c = cache[name] || (cache[name] = mkFreshComponent())
    return f(c)
  }
})()

exports.withFreshComponent = function(f) {
  return f(mkFreshComponent())
}

exports.instantiateBaseComponent = React.createElement

function mkFreshComponent() {
  function ElmishComponent() {}
  ElmishComponent.prototype = Object.create(React.Component.prototype)
  ElmishComponent.prototype.render = function() {
    return this.props.render(this)()
  }
  ElmishComponent.prototype.componentDidMount = function() {
    this.props.componentDidMount(this)()
  }

  return ElmishComponent
}
