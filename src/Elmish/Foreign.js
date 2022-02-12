export function isString(s) {
  return typeof s === "string"
}

export function isNumber(s) {
  return typeof s === "number"
}

export function isBoolean(s) {
  return typeof s === "boolean"
}

export function isDate(s) {
  return s instanceof Date
}

export function isObject(s) {
  return s instanceof Object
}

export function isFunction(s) {
  return s instanceof Function
}

export function showForeign(x) {
  return (
    x === null ? "<null>"
    : x === undefined ? "<undefined>"
    : x instanceof Date ? x.toString()
    : (typeof Blob !== "undefined" && x instanceof Blob) ? "file[" + x.name + "]"
    : JSON.stringify(x)
  )
}

export function mkVarArgEff_(k) {
  return function() {
    k(arguments)()
  }
}

export function getArgument_(args) {
  return function(index) {
    return function(just) {
      return function(nothing) {
        return args.length > index ? just(args[index]) : nothing
      }
    }
  }
}

export function argumentsToArray_(args) {
  return Array.from(args)
}
