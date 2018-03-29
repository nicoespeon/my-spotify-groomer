port module MySpotifyGroomer exposing (main)

import Html exposing (Html, programWithFlags, h1, div, text, nav)
import Html.Attributes exposing (class)
import Http exposing (Request)
import Navigation exposing (load)
import Playlist exposing (Playlist)
import SemanticUI exposing (confirm, loader, loaderBlock)
import Spotify exposing (Offset, Limit)
import Track exposing (TrackUri)
import Task exposing (Task)
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
    = Blank
    | Loading
    | Loaded
    | Errored String


type alias Flags =
    { useFakeSpotifyApi : Bool
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( emptyModel flags, setReferenceTimeToNow )


emptyModel : Flags -> Model
emptyModel flags =
    { accessToken = ""
    , state = Blank
    , user = User "" "" Nothing
    , playlist = Playlist.emptyModel
    , referenceTime = 0
    , useFakeSpotifyApi = flags.useFakeSpotifyApi
    }



-- UPDATE


type Msg
    = ReferenceTimeSet Time
    | LogIn AccessToken
    | UserMsg User.Msg
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
            ReferenceTimeSet time ->
                ( { model | referenceTime = time }, Cmd.none )

            LogIn accessToken ->
                ( { model | state = Loading, accessToken = accessToken }
                , fetchUser spotify.getCurrentUserProfile
                )

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

                            User.FetchFailed ->
                                ( Errored "Failed to fetch user data."
                                , load "/login"
                                )
                in
                    ( { model | state = newState, user = newUser }, newCmd )

            PlaylistMsg playlistMsg ->
                let
                    ( newPlaylist, newPlaylistMsg ) =
                        Playlist.update
                            (spotify.getCurrentUserPlaylists)
                            (spotify.getPlaylistTracks)
                            (spotify.removeTracksFromPlaylist model.user.id)
                            model.referenceTime
                            model.user.id
                            playlistMsg
                            model.playlist
                in
                    ( { model | state = Loaded, playlist = newPlaylist }
                    , Cmd.map PlaylistMsg newPlaylistMsg
                    )


setReferenceTimeToNow : Cmd Msg
setReferenceTimeToNow =
    Task.perform ReferenceTimeSet Time.now


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
        Blank ->
            text ""

        Loading ->
            loader "Fetching data from Spotify…"

        Loaded ->
            div []
                [ mainNav model.user
                , mainContainer
                    [ pageTitle
                    , Playlist.view model.playlist |> Html.map PlaylistMsg
                    ]
                ]

        Errored message ->
            text ("An error occurred: " ++ message)


mainContainer : List (Html Msg) -> Html Msg
mainContainer =
    div [ class "ui main text container" ]


pageTitle : Html Msg
pageTitle =
    h1 [] [ text "Groom your Spotify playlists" ]


mainNav : User -> Html Msg
mainNav user =
    nav
        [ class "ui fixed borderless secondary pointing nav menu" ]
        [ div
            [ class "ui container" ]
            [ div
                [ class "header item" ]
                [ User.view user ]
            ]
        ]



-- SUBSCRIPTIONS


port accessToken : (String -> a) -> Sub a


subscriptions : Model -> Sub Msg
subscriptions model =
    accessToken LogIn
