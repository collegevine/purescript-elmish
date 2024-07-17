import React from "react";

export var withCachedComponent = (function() {
  const cache = {}

  return function(name, f) {
    const c = cache[name] || (cache[name] = mkFreshComponent(name))
    return f(c)
  }
})();

export function withFreshComponent(f) {
  return f(mkFreshComponent())
}

export var instantiateBaseComponent = React.createElement;

export const instancePropDef = component => () => component.props.def

function mkFreshComponent(name) {
  class ElmishComponent extends React.Component {
    constructor(props) {
      super(props)
      props.init && props.init(this)()
    }

    render() {
      return this.props.render(this)()
    }

    componentDidMount() {
      this.props.componentDidMount(this)()
    }

    componentWillUnmount() {
      this.props.componentWillUnmount(this)()
    }
  }

  ElmishComponent.displayName = name ? ("Elmish_" + name) : "ElmishRoot"
  return ElmishComponent
}
