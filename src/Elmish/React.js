import React from "react";
import ReactDOM from "react-dom";
import ReactDOMServer from "react-dom/server.js";

export function getState_(component) {
  return component.state && component.state.s;
}

export function setState_(component, state, callback) {
  return component.setState({ s: state }, callback);
}

export function assignState_(component, state) {
  return component.state = { s: state };
}

export var render_ = ReactDOM.render;
export var hydrate_ = ReactDOM.hydrate;
export var renderToString = (ReactDOMServer && ReactDOMServer.renderToString) || (_ => "");
export var unmount_ = ReactDOM.unmountComponentAtNode

export var fragment_ = React.Fragment;

export var appendElement_ = a => b => {
  const childrenOf = x => {
    if (x === false || x === null || typeof x === 'undefined') return []
    if (x.type === React.Fragment) {
      const children = x.props?.children
      if (children instanceof Array) return children
      if (children === false || children === null || typeof children === 'undefined') return []
      return [children]
    }
    return [x]
  }
  const allChildren = [...childrenOf(a), ...childrenOf(b)]
  return allChildren.length === 0 ? false : React.createElement(React.Fragment, null, allChildren)
}

export function createElement_(component, props, children) {
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

export const getField_ = (field, obj) => obj[field]
export const setField_ = (field, value, obj) => obj[field] = value
