port module MySpotifyGroomer exposing (..)

import Html exposing (Html, program, button, div, span, text, a, img, h2)
import Html.Attributes exposing (src, class)
import Http exposing (Error, Request, header, emptyBody, expectJson)
import Navigation exposing (load)
import Json.Decode as Decode exposing (Decoder, at, list, string, int)
import Task exposing (Task)


main : Program Never Model Msg
main =
    program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { accessToken : String
    , fetchStatus : FetchStatus
    , user : User
    , playlists : List Playlist
    }


type alias User =
    { name : String
    , profilePictureUrl : Maybe String
    }


type alias Playlist =
    { name : String
    , tracksUrl : String
    , tracks : List Track
    }


type alias Track =
    { name : String
    , popularity : Int
    }


type alias TracksResponse =
    { tracks : List Track
    , next : Maybe String
    }


type FetchStatus
    = NotStarted
    | FetchingUser
    | FetchingPlaylists
    | Error
    | Success



-- INIT


init : ( Model, Cmd Msg )
init =
    ( emptyModel, Cmd.none )


emptyModel : Model
emptyModel =
    { accessToken = ""
    , fetchStatus = NotStarted
    , user = User "" Nothing
    , playlists = []
    }



-- UPDATE


type Msg
    = LogIn AccessToken
    | FetchUser (Result Error User)
    | FetchPlaylists (Result Error (List Playlist))


type alias AccessToken =
    String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LogIn accessToken ->
            ( { model | fetchStatus = FetchingUser, accessToken = accessToken }, fetchUser accessToken )

        FetchUser (Ok user) ->
            ( { model | fetchStatus = FetchingPlaylists, user = user }, fetchPlaylistsWithTracks model.accessToken )

        FetchUser (Err _) ->
            ( { model | fetchStatus = Error }, load "/login" )

        FetchPlaylists (Ok playlists) ->
            ( { model | fetchStatus = Success, playlists = playlists }, Cmd.none )

        FetchPlaylists (Err _) ->
            ( { model | fetchStatus = Error }, Cmd.none )


getFromSpotify : AccessToken -> String -> Decoder a -> Request a
getFromSpotify accessToken url decoder =
    let
        authorizationHeader =
            header "Authorization" ("Bearer " ++ accessToken)
    in
        Http.request
            { method = "GET"
            , headers = [ authorizationHeader ]
            , url = url
            , body = emptyBody
            , expect = expectJson decoder
            , timeout = Nothing
            , withCredentials = False
            }


fetchUser : AccessToken -> Cmd Msg
fetchUser accessToken =
    let
        url =
            "https://api.spotify.com/v1/me"
    in
        Http.send FetchUser (getFromSpotify accessToken url userDecoder)


fetchPlaylistsWithTracks : AccessToken -> Cmd Msg
fetchPlaylistsWithTracks accessToken =
    fetchPlaylists accessToken
        |> Task.andThen (fetchPlaylistsTracks accessToken)
        |> Task.attempt FetchPlaylists


fetchPlaylists : AccessToken -> Task Error (List Playlist)
fetchPlaylists accessToken =
    let
        url =
            "https://api.spotify.com/v1/me/playlists?fields=items(name,tracks.href)&limit=50"
    in
        getFromSpotify accessToken url playlistsDecoder
            |> Http.toTask


fetchPlaylistsTracks : AccessToken -> List Playlist -> Task Error (List Playlist)
fetchPlaylistsTracks accessToken playlists =
    playlists
        |> List.map (fetchPlaylistTracks accessToken)
        |> Task.sequence


fetchPlaylistTracks : AccessToken -> Playlist -> Task Error Playlist
fetchPlaylistTracks accessToken playlist =
    let
        url =
            playlist.tracksUrl ++ "?fields=items(track.name,track.popularity),next"
    in
        fetchPlaylistTracksWithUrl accessToken playlist url


fetchPlaylistTracksWithUrl : AccessToken -> Playlist -> String -> Task Error Playlist
fetchPlaylistTracksWithUrl accessToken playlist url =
    getFromSpotify accessToken url tracksDecoder
        |> Http.toTask
        |> Task.andThen
            (\tracks ->
                case tracks.next of
                    Just nextUrl ->
                        updatePlaylistWithTracks playlist tracks.tracks
                            |> Task.andThen
                                (\newPlaylist -> fetchPlaylistTracksWithUrl accessToken newPlaylist nextUrl)

                    Nothing ->
                        updatePlaylistWithTracks playlist tracks.tracks
            )


updatePlaylistWithTracks : Playlist -> List Track -> Task Error Playlist
updatePlaylistWithTracks playlist tracks =
    let
        newTracks =
            playlist.tracks
                |> List.append tracks
                |> List.filter (\track -> track.popularity < 20)
    in
        Task.succeed { playlist | tracks = newTracks }



-- DECODERS


userDecoder : Decoder User
userDecoder =
    Decode.map2 User
        (at [ "display_name" ] string)
        (Decode.map
            List.head
            (at [ "images" ] (list (at [ "url" ] string)))
        )


playlistsDecoder : Decoder (List Playlist)
playlistsDecoder =
    at [ "items" ]
        (Decode.list
            (Decode.map3 Playlist
                (at [ "name" ] string)
                (at [ "tracks", "href" ] string)
                (Decode.succeed [])
            )
        )


tracksDecoder : Decoder TracksResponse
tracksDecoder =
    Decode.map2 TracksResponse
        (at [ "items" ]
            (Decode.list
                (Decode.map2 Track
                    (at [ "track", "name" ] string)
                    (at [ "track", "popularity" ] int)
                )
            )
        )
        (Decode.maybe (at [ "next" ] string))



-- VIEW


view : Model -> Html Msg
view model =
    case model.fetchStatus of
        NotStarted ->
            text "Fetch of data has not started yet."

        FetchingUser ->
            text "Fetching user data from Spotify…"

        Error ->
            text "Something went wrong when data were fetched!"

        FetchingPlaylists ->
            div []
                [ renderUser model.user
                , text "Fetching playlists data from Spotify…"
                ]

        Success ->
            div []
                [ renderUser model.user
                , div
                    [ class "ui relaxed divided list" ]
                    (List.map renderPlaylist model.playlists)
                ]


renderUser : User -> Html Msg
renderUser user =
    case user.profilePictureUrl of
        Just profilePictureUrl ->
            div []
                [ img [ class "ui avatar image", src profilePictureUrl ] []
                , span [] [ text ("Hello " ++ user.name) ]
                ]

        Nothing ->
            text ("Hello " ++ user.name)


renderPlaylist : Playlist -> Html Msg
renderPlaylist playlist =
    div [ class "item" ]
        [ h2 []
            [ text (playlist.name ++ " (" ++ toString (List.length playlist.tracks) ++ ")")
            ]
        , div [ class "ui list" ]
            (playlist.tracks
                |> List.sortBy .popularity
                |> List.map renderTrack
            )
        ]


renderTrack : Track -> Html Msg
renderTrack track =
    div [ class "item" ]
        [ text ("(" ++ (toString track.popularity) ++ ") " ++ track.name) ]



-- SUBSCRIPTIONS


port accessToken : (String -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    accessToken LogIn
