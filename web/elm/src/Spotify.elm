module Spotify exposing (AccessToken, get, getRequest, delete)

import Http exposing (Header, Request, Error, header, emptyBody, jsonBody, expectJson)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)


type alias AccessToken =
    String


type alias Url =
    String


spotifyBaseUrl : Url
spotifyBaseUrl =
    "https://api.spotify.com/v1"


authorizationHeader : AccessToken -> Header
authorizationHeader accessToken =
    header "Authorization" ("Bearer " ++ accessToken)


toSpotifyUrl : Url -> Url
toSpotifyUrl url =
    if (String.startsWith spotifyBaseUrl url) then
        url
    else
        spotifyBaseUrl ++ url


getRequest : AccessToken -> Url -> Decoder a -> Request a
getRequest accessToken url decoder =
    Http.request
        { method = "GET"
        , headers = [ authorizationHeader accessToken ]
        , url = toSpotifyUrl url
        , body = emptyBody
        , expect = expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }


get : (Result Error a -> b) -> AccessToken -> Url -> Decoder a -> Cmd b
get msg accessToken url decoder =
    Http.send msg (getRequest accessToken url decoder)


delete : (Result Error a -> b) -> AccessToken -> Url -> Value -> Decoder a -> Cmd b
delete msg accessToken url body decoder =
    let
        request =
            Http.request
                { method = "DELETE"
                , headers = [ authorizationHeader accessToken ]
                , url = toSpotifyUrl url
                , body = jsonBody body
                , expect = expectJson decoder
                , timeout = Nothing
                , withCredentials = False
                }
    in
        Http.send msg request
