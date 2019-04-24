const React = require("react")

export const mkFreshComponent = () => {
  // This class is actually part of `Component.purs`, but needs to be in a separate module,
  // because Purescript doesn't understand ES6+ features, and can't parse a class declaration.
  // (and I already forgot how to imitate JS classes in the hacky prototype+constructor way)
  return class extends React.Component {
    render() {
      return this.props.render(this)()
    }
    componentDidMount() {
      this.props.componentDidMount(this)()
    }
  }
}
