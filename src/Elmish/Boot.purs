module Elmish.Boot
    ( BootRecord
    , boot
    , defaultMain
    ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console as Console
import Elmish.Component as Comp
import Elmish.React as React
import Web.DOM.NonElementParentNode (getElementById) as DOM
import Web.HTML (window) as DOM
import Web.HTML.HTMLDocument (toNonElementParentNode) as DOM
import Web.HTML.Window (document) as DOM

-- | Support for the most common case entry point - i.e. mounting an Elmish
-- | component (i.e. `ComponentDef'` structure) to an HTML DOM element with a
-- | known ID, with support for server-side rendering.
-- |
-- | The function `boot` returns what we call `BootRecord` - a record of three
-- | functions:
-- |
-- |    * `mount` - takes HTML element ID and props¹, creates an instance of the
-- |       component, and mounts it to the HTML element in question
-- |    * `hydrate` - same as `mount`, but expects the HTML element to already
-- |       contain pre-rendered HTML inside. See React docs for more on
-- |       server-side rendering:
-- |       https://reactjs.org/docs/react-dom.html#hydrate
-- |    * `renderToString` - meant to be called on the server (e.g. by running
-- |       the code under NodeJS) to perform the server-side render. Takes
-- |       props¹ and returns a `String` containing the resulting HTML.
-- |
-- | The idea is that the PureScript code would export such `BootRecord` for
-- | consumption by bootstrap JavaScript code in the page and/or server-side
-- | NodeJS code (which could be written in PureScript or not). For "plain
-- | React" scenario, the JavaScript code in the page would just call `mount`.
-- | For "server-side rendering", the server would first call `renderToString`
-- | and serve the HTML to the client, and then the client-side JavaScript code
-- | would call `hydrate`.
-- |
-- | -------------------------------------------------------------------------
-- |  ¹ "props" here is a parameter used to instantiate the component (see
-- |  example below). It is recommended that this parameter is a JavaScript
-- |  record (hence the name "props"), because it would likely need to be
-- |  supplied by some bootstrap JavaScript code.
-- |
-- | -------------------------------------------------------------------------
-- |
-- | Example:
-- |
-- |     -- PureScript:
-- |     module Foo(bootRecord) where
-- |
-- |     type Props = { hello :: String, world :: Int }
-- |
-- |     component :: Props -> ComponentDef' Aff Message State
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


-- | Creates a boot record for the given component. See comments for `BootRecord`.
boot :: forall msg state props. (props -> Comp.ComponentDef msg state) -> BootRecord props
boot mkDef =
  { mount: mountVia React.render
  , renderToString
  , hydrate: mountVia React.hydrate
  }
  where
    renderToString props = React.renderToString $ def.view state0 (const $ pure unit)
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
          f render e

-- | This function supports the simplest (almost toy?) use case where there is
-- | no server, no server-side rendering, all that exists is an HTML page that
-- | loads the JS bundle (compiled from PureScript), and expects the bundle to
-- | breath life into the page. For this case, declare your bundle entry point
-- | (i.e. your `main` function) as a call to `defaultMain`, passing it DOM
-- | element ID to bind to and the UI component to bind to it.
-- |
-- | Example:
-- |
-- |     module Main
-- |     import MyComponent(def)
-- |     import Elmish.Boot as Boot
-- |
-- |     main :: Effect Unit
-- |     main = Boot.defaultMain { elementId: "app", def: def }
-- |
defaultMain :: forall msg state. { elementId :: String, def :: Comp.ComponentDef msg state } -> Effect Unit
defaultMain { elementId, def } =
    bootRec.mount elementId unit
    where
        bootRec = boot \_ -> def
