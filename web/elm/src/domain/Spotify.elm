module Spotify exposing (Url, Offset, Limit, IsLocal, toSpotifyUrl)


type alias Url =
    String


type alias Offset =
    Int


type alias Limit =
    Int


type alias IsLocal =
    Bool


toSpotifyUrl : Url -> Url -> Url
toSpotifyUrl spotifyBaseUrl url =
    if (String.startsWith spotifyBaseUrl url) then
        url
    else
        spotifyBaseUrl ++ url
