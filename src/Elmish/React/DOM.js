const React = require("react")
const ReactDOM = require("react-dom")


exports.fragment_ = React.Fragment

exports.render = function(reactElement) {
  return function(domElement) {
    return function() {
      ReactDOM.render(reactElement, domElement)
    }
  }
}
exports.unmountComponentAtNode = function(domElement) {
  return function() {
    ReactDOM.unmountComponentAtNode(domElement)
  }
}
