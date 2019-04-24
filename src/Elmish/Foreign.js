exports.isString = function(s) {
  return typeof s === "string"
}
exports.isNumber = function(s) {
  return typeof s === "number"
}
exports.isBoolean = function(s) {
  return typeof s === "boolean"
}
exports.isDate = function(s) {
  return s instanceof Date
}
exports.isObject = function(s) {
  return s instanceof Object
}
exports.isFunction = function(s) {
  return s instanceof Function
}

exports.showForeign = function(x) {
  return x === null
    ? "<null>"
    : x === undefined
    ? "<undefined>"
    : x instanceof Date
    ? x.toString()
    : x instanceof Blob
    ? "file[" + x.name + "]"
    : JSON.stringify(x)
}

exports.mkVarArgEff_ = function(k) {
  return function() {
    k(arguments)()
  }
}

exports.getArgument_ = function(args) {
  return function(index) {
    return function(just) {
      return function(nothing) {
        return args.length > index ? just(args[index]) : nothing
      }
    }
  }
}

exports.argumentsToArray_ = function(args) {
  return Array.from(args)
}
