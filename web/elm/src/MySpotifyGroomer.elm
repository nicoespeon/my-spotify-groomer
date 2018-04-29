port module MySpotifyGroomer exposing (main)

import Error exposing (Error)
import Html exposing (Html, programWithFlags, h1, div, text)
import Html.Attributes exposing (class)
import Http exposing (Request)
import Playlist exposing (Playlist)
import SemanticUI exposing (confirm, loader, loaderBlock)
import Spotify exposing (Offset, Limit)
import Track exposing (TrackUri)
import Time exposing (Time)
import User exposing (User, UserId)


-- Infrastructure imports

import SpotifyHttp exposing (AccessToken)
import FakeSpotifyHttp


main : Program Flags Model Msg
main =
    programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { accessToken : AccessToken
    , state : State
    , user : User
    , playlist : Playlist.Model
    , referenceTime : Time
    , useFakeSpotifyApi : Bool
    }


type State
    = Loading
    | Loaded


type alias Flags =
    { useFakeSpotifyApi : Bool
    , accessToken : AccessToken
    , referenceTime : Time
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        spotify =
            if flags.useFakeSpotifyApi then
                FakeSpotifyHttp.fakeSpotifyHttp
            else
                SpotifyHttp.spotifyHttp flags.accessToken
    in
        ( initModel flags, fetchUser spotify.getCurrentUserProfile )


initModel : Flags -> Model
initModel flags =
    { accessToken = flags.accessToken
    , state = Loading
    , user = User "" "" Nothing
    , playlist = Playlist.emptyModel
    , referenceTime = flags.referenceTime
    , useFakeSpotifyApi = flags.useFakeSpotifyApi
    }



-- UPDATE


type Msg
    = UserMsg User.Msg
    | PlaylistMsg Playlist.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        spotify =
            if model.useFakeSpotifyApi then
                FakeSpotifyHttp.fakeSpotifyHttp
            else
                SpotifyHttp.spotifyHttp model.accessToken
    in
        case msg of
            UserMsg userMsg ->
                let
                    ( newUser, msgFromUser ) =
                        User.update userMsg model.user

                    ( newState, newCmd ) =
                        case msgFromUser of
                            User.UserSet ->
                                ( Loaded
                                , fetchFavoriteTracks spotify.getCurrentUserTopTracks
                                )

                            User.FetchFailed error ->
                                ( model.state, sendError error )
                in
                    ( { model | state = newState, user = newUser }, newCmd )

            PlaylistMsg playlistMsg ->
                let
                    ( newPlaylist, newPlaylistMsg ) =
                        Playlist.update
                            (spotify.getCurrentUserPlaylists)
                            (spotify.getPlaylistTracks)
                            (spotify.removeTracksFromPlaylist model.user.id)
                            sendError
                            model.referenceTime
                            model.user.id
                            playlistMsg
                            model.playlist
                in
                    ( { model | state = Loaded, playlist = newPlaylist }
                    , Cmd.map PlaylistMsg newPlaylistMsg
                    )


fetchUser : Request User -> Cmd Msg
fetchUser getCurrentUserProfile =
    User.fetchData getCurrentUserProfile
        |> Cmd.map UserMsg


fetchFavoriteTracks : (Offset -> Limit -> Request (List TrackUri)) -> Cmd Msg
fetchFavoriteTracks getCurrentUserTopTracks =
    Playlist.fetchFavoriteTracks getCurrentUserTopTracks
        |> Cmd.map PlaylistMsg



-- VIEW


view : Model -> Html Msg
view model =
    case model.state of
        Loading ->
            loader "Fetching data from Spotify…"

        Loaded ->
            div [ class "push-bottom" ]
                [ mainNav model.user
                , mainContainer
                    [ pageTitle
                    , Playlist.view model.playlist |> Html.map PlaylistMsg
                    ]
                ]


mainContainer : List (Html Msg) -> Html Msg
mainContainer =
    div [ class "ui main text container" ]


pageTitle : Html Msg
pageTitle =
    h1 [] [ text "Groom your Spotify playlists" ]


mainNav : User -> Html Msg
mainNav user =
    div
        [ class "ui fixed borderless secondary pointing nav menu" ]
        [ div
            [ class "ui container" ]
            [ User.view user ]
        ]



-- SUBSCRIPTIONS


port sendError : Error -> Cmd a


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
