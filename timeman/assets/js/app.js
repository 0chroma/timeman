// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"

import { Elm } from '../elm/src/Main.elm';

// Initial data passed to Elm (should match `Flags` defined in `Shared.elm`)
// https://guide.elm-lang.org/interop/flags.html
var flags = {
  user: JSON.parse(localStorage.getItem('user')) || null
}

// Start our Elm application
var app = Elm.Main.init({ flags: flags })

// Ports go here
// https://guide.elm-lang.org/interop/ports.html
app.ports.outgoing.subscribe(({ tag, data }) => {
  switch (tag) {
    case 'saveUser':
      return localStorage.setItem('user', JSON.stringify(data))
    case 'clearUser':
      return localStorage.removeItem('user')
    default:
      return console.warn(`Unrecognized Port`, tag)
  }
})
