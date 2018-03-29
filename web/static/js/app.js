// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
// import 'phoenix_html';

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"

((document, window) => {
  if (!window.location.hash) return redirectToLoginPage(window);

  const hashParts = window.location.hash.match(/access_token=(.*)&token_type/);
  if (!hashParts) return redirectToLoginPage(window);

  const accessToken = hashParts[1];

  const elmContainer = document.getElementById('my-spotify-groomer');
  if (!elmContainer) return;

  const elmApp = Elm.MySpotifyGroomer.embed(elmContainer, {
    useFakeSpotifyApi: false
  });
  elmApp.ports.accessToken.send(accessToken);
})(document, window);

function redirectToLoginPage(window) {
  const isOnLoginPage = /\/login$/.test(window.location.href);
  if (!isOnLoginPage) {
    window.location.replace('/login');
  }
}
