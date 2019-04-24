const React = require("react")
const ReactDOM = require("react-dom")

exports.getState = function(component) {
  return function() {
    return component.state && component.state.s
  }
}
exports.setState = function(component, state, callback) {
  return function() {
    component.setState({ s: state }, callback)
  }
}

exports.reactMount = function(el, jsxDom) {
  return function() {
    ReactDOM.render(jsxDom, el)
  }
}
exports.reactUnmount = function(el) {
  return function() {
    ReactDOM.unmountComponentAtNode(el)
  }
}

exports.createElement_ = function(component, props, children) {
  // The type of `children` is `Array ReactElement`. If we pass that in as
  // third parameter of `React.createElement` directly, React complains about
  // missing `key`s. Instead, we pass it as an array to
  // `React.createElement.apply`. This is the equivalent of turning
  // `React.createElement(component, props, [a, b, c])` into
  // `React.createElement(component, props, a, b, c)`.
  //
  // Once PureScript FFI officially supports ES2015, we could make it nicer
  // using the spread syntax:
  //
  //  return React.createElement(component, props, ...children)
  //
  return React.createElement.apply(null, [component, props].concat(children))
}
