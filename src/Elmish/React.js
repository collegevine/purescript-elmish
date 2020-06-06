const React = require("react")
const ReactDOM = require("react-dom")
const ReactDOMServer = require("react-dom/server")

exports.getState_ = component => component.state && component.state.s
exports.setState_ = (component, state, callback) => component.setState({ s: state }, callback)

exports.render_ = ReactDOM.render
exports.hydrate_ = ReactDOM.hydrate
exports.renderToString = ReactDOMServer ? ReactDOMServer.renderToString : (_ => "")

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
  //  HTML `data-` attributes
  //  =======================
  //
  // `props` accepts a special-cased `_data` object that is translated into HTML
  // `data-` attributes, e.g.
  //
  //  var component = "div"
  //  var props = { id: "viewer", _data: { toggle: "buttons", label: "toolbar" } }
  //
  //  results in
  //
  //  <div id="viewer" data-toggle="buttons" data-label="toolbar" />
  //
  return React.createElement.apply(
    null,
    [component, flattenDataProp(component, props)].concat(children)
  )
}

// Flattens special `_data` `props` object into `data-` HTML attributes. This
// is skipped for non-HTML components, i.e. custom components, as well as if
// `_data` is not present in `props`:
function flattenDataProp(component, props) {
  if (typeof component !== "string" || props._data == null) {
    return props
  }

  var data = { _data: undefined }
  for (var key in props._data) {
    var value = props._data[key]
    data["data-" + key] = value
  }
  return Object.assign({}, props, data)
}
