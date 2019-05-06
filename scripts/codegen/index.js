const fs = require("fs")
const path = require("path")

const { props, voids, types, typesByElement, reserved } = require("./consts")
const genFile = path.join(
  __dirname,
  "../../src/Elmish/React/DOM/Generated.purs"
)

const header = `-- | ---------------------------------------------------------------------------
-- | THIS FILE IS GENERATED -- DO NOT EDIT IT
-- | ---------------------------------------------------------------------------

module Elmish.React.DOM.Generated where

import Prelude

import Elmish (JsCallback0)
import Elmish.React (ReactElement, createElement, createElement')
import Elmish.React.DOM.Internal (CSS, unsafeCreateDOMComponent)
import Elmish.React.Import (EmptyProps, ImportedReactComponentConstructor, ImportedReactComponentConstructorWithContent)

`

const propType = (e, p) => {
  const elPropTypes = typesByElement[p]
  if (elPropTypes) {
    if (types[p]) {
      throw new TypeError(`${p} appears in both types and typesByElement`)
    }
    return elPropTypes[e] || elPropTypes["*"] || "String"
  } else {
    return types[p] || "String"
  }
}

const printRow = (e, elProps) =>
  elProps.length > 0
    ? `
  ( ${elProps.map(p => `${p} :: ${propType(e, p)}`).join("\n  , ")}
  | r
  )`
    : "( | r )"

const domTypes = props.elements.html
  .map(e => {
    const hasChildren = !voids.includes(e)
    const symbol = reserved.includes(e) ? `${e}'` : e
    return `
    type OptProps_${e} r =${printRow(
      e,
      [].concat(props[e] || [], props["*"] || []).sort()
    )}

    ${
      hasChildren
        ? `
    ${symbol} :: ImportedReactComponentConstructorWithContent EmptyProps OptProps_${e}
    ${symbol} = createElement $ unsafeCreateDOMComponent "${e}"
    `
        : `
    ${symbol} :: ImportedReactComponentConstructor EmptyProps OptProps_${e}
    ${symbol} = createElement' $ unsafeCreateDOMComponent "${e}"
    `
    }
`
  })
  .map(x => x.replace(/^\n\ {4}/, "").replace(/\n\ {4}/g, "\n"))
  .join("\n")

console.log(`Writing "${genFile}" ...`)
fs.writeFileSync(genFile, header + domTypes)
console.log("Done.")
