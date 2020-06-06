-- | Support for the most common case entry point - i.e. mounting an Elmish
-- | component (i.e. `ComponentDef` structure) to an HTML DOM element with a
-- | known ID, with support for server-side rendering.
-- |
-- | The function `boot` returns what we call `BootRecord` - a record of three
-- | functions:
-- |
-- |     * `mount` -
-- |        takes HTML element ID and props¹, creates an instance of
-- |        the component, and mounts it to the HTML element in question
-- |     * `hydrate` -
-- |        same as `mount`, but expects the HTML element to already
-- |        contain pre-rendered HTML inside. See React docs for more
-- |        on server-side rendering: https://reactjs.org/docs/react-dom.html#hydrate
-- |     * `renderToString` -
-- |        meant to be called on the server (e.g. by running the code
-- |        under NodeJS) to perform the server-side render. Takes props¹
-- |        and returns a `String` containing the resulting HTML.
-- |
-- | The idea is that the PureScript code would export such `BootRecord` for
-- | consumption by bootstrap JavaScript code in the page and/or server-side
-- | NodeJS code (which could be written in PureScript or not). For "plan React"
-- | scenario, the JavaScript code in the page would just call `mount`. For
-- | "server-side rendering", the server would first call `renderToString` and
-- | serve the HTML to the client, and then the client-side JavaScript code
-- | would call `hydrate`.
-- |
-- | -------------------------------------------------------------------------
-- |  ¹ "props" here is a parameter used to instantiate the component (see
-- |  example below). It is recommended that this parameter is a JavaScript
-- |  record (hence the name "props"), because it would likely need to be
-- |  supplied by some bootstrap JavaScript code.
-- | -------------------------------------------------------------------------
-- |
-- | Example:
-- |
-- |     -- PureScript:
-- |     module Foo(bootRecord) where
-- |
-- |     type Props = { hello :: String, world :: Int }
-- |
-- |     component :: Props -> ComponentDef Aff Message State
-- |     component = ...
-- |
-- |     bootRecord :: BootRecord Props
-- |     bootRecord = boot component
-- |
-- |
-- |     // Server-side JavaScript NodeJS code
-- |     const foo = require('output/Foo/index.js')
-- |     const fooHtml = foo.bootRecord.renderToString({ hello: "Hi!", world: 42 })
-- |     serveToClient("<html><body><div id='foo'>" + fooHtml + "</div></body></html>")
-- |
-- |
-- |     // Client-side HTML + JS:
-- |     <html>
-- |        <body>
-- |          <div id='foo'>
-- |            ... server-side-rendered HTML goes here
-- |          </div>
-- |        </body>
-- |        <script src="foo_bundle.js" />
-- |        <script>
-- |          Foo.bootRecord.hydrate('foo', { hello: "Hi!", world: 42 })
-- |        </script>
-- |     </html>
-- |
module Elmish.Boot
    ( BootRecord
    , boot
    ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class.Console as Console
import Elmish.Component as Comp
import Elmish.Dispatch (DispatchMsgFn, dispatchMsgFn)
import Elmish.React as React
import Web.DOM.NonElementParentNode (getElementById) as DOM
import Web.HTML (window) as DOM
import Web.HTML.HTMLDocument (toNonElementParentNode) as DOM
import Web.HTML.Window (document) as DOM

type BootRecord props =
  { mount :: String -> props -> Effect Unit
  -- ^ Mount the component to a DOM element with given string ID

  , renderToString :: props -> String
  -- ^ Server-side render: render the component as an HTML string

  , hydrate :: String -> props -> Effect Unit
  -- ^ Mount the component to a DOM element with given string ID, where the DOM
  -- element is expected to have HTML contents previously generated via
  -- `renderToString`. See React docs for more gotchas:
  -- https://reactjs.org/docs/react-dom.html#hydrate
  }

boot :: forall msg state props. (props -> Comp.ComponentDef Aff msg state) -> BootRecord props
boot mkDef =
  { mount: mountVia React.render
  , renderToString
  , hydrate: mountVia React.hydrate
  }
  where
    renderToString props = React.renderToString $ def.view state0 onError
      where
        def = mkDef props
        Comp.Transition state0 _ = def.init

    mountVia f domElementId props =
      DOM.window
      >>= (map DOM.toNonElementParentNode <<< DOM.document)
      >>= DOM.getElementById domElementId
      >>= case _ of
        Nothing ->
          Console.error $ "Element #" <> domElementId <> " not found"
        Just e -> do
          render <- Comp.construct (mkDef props)
          f (render onError) e

    onError :: forall a. DispatchMsgFn a
    onError = dispatchMsgFn Console.error (const $ pure unit)
