port module MySpotifyGroomer exposing (main)

import Html exposing (Html, program, h1, div, text, nav)
import Html.Attributes exposing (class)
import Http exposing (Error)
import Navigation exposing (load)
import SemanticUI exposing (confirm, loader, loaderBlock)
import Spotify exposing (AccessToken, get, getRequest, delete)
import Task exposing (Task)
import Time exposing (Time)
import Track exposing (Track, TrackUri, Playlist, PlaylistId)
import User exposing (User, UserId)


main : Program Never Model Msg
main =
    program
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
    , playlists : List Playlist
    , favoriteTracks : List TrackUri
    , referenceTime : Time
    }


type State
    = Blank
    | Loading
    | Errored String
    | AskingToDeleteTrack Playlist Track
    | LoadingPlaylists String
    | PlaylistSelection
    | LoadingTracks
    | PlaylistTracks Playlist
    | DeletingTrack


init : ( Model, Cmd Msg )
init =
    ( emptyModel, setReferenceTimeToNow )


emptyModel : Model
emptyModel =
    { accessToken = ""
    , state = Blank
    , user = User "" "" Nothing
    , playlists = []
    , favoriteTracks = []
    , referenceTime = 0
    }



-- UPDATE


type Msg
    = ReferenceTimeSet Time
    | LogIn AccessToken
    | UserMsg User.Msg
    | FavoriteTracksFetched (Result Error (List TrackUri))
    | PlaylistsFetched (Result Error (List Playlist))
    | SelectPlaylist PlaylistId
    | PlaylistTracksFetched (Result Error Playlist)
    | AskToDeleteTrack Playlist Track
    | DeleteTrack PlaylistId TrackUri
    | TrackDeleted PlaylistId (Result Error (List Playlist))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReferenceTimeSet time ->
            ( { model | referenceTime = time }, Cmd.none )

        LogIn accessToken ->
            ( { model | state = Loading, accessToken = accessToken }
            , fetchUser accessToken
            )

        UserMsg userMsg ->
            let
                ( newUser, msgFromUser ) =
                    User.update userMsg model.user

                ( newState, newCmd ) =
                    case msgFromUser of
                        User.UserSet ->
                            ( LoadingPlaylists "Fetching your favorite tracks…"
                            , fetchFavoriteTracks model.accessToken
                            )

                        User.FetchFailed ->
                            ( Errored "Failed to fetch user data."
                            , load "/login"
                            )
            in
                ( { model | state = newState, user = newUser }, newCmd )

        FavoriteTracksFetched (Ok trackUris) ->
            ( { model
                | state = LoadingPlaylists "Fetching your playlists…"
                , favoriteTracks = trackUris
              }
            , fetchPlaylists model.accessToken
            )

        FavoriteTracksFetched (Err _) ->
            ( { model | state = Errored "Failed to fetch user top tracks." }
            , Cmd.none
            )

        PlaylistsFetched (Ok playlists) ->
            ( { model
                | state = PlaylistSelection
                , playlists = playlistsOwnedByUser model.user.id playlists
              }
            , Cmd.none
            )

        PlaylistsFetched (Err _) ->
            ( { model | state = Errored "Failed to fetch user playlists." }
            , Cmd.none
            )

        SelectPlaylist playlistId ->
            case Track.selectedPlaylist playlistId model.playlists of
                Just playlist ->
                    ( { model | state = LoadingTracks }
                    , fetchPlaylistTracks model playlist
                    )

                Nothing ->
                    ( model, Cmd.none )

        PlaylistTracksFetched (Ok playlist) ->
            ( { model | state = PlaylistTracks playlist }, Cmd.none )

        PlaylistTracksFetched (Err _) ->
            ( { model | state = Errored "Failed to fetch playlist tracks." }
            , Cmd.none
            )

        AskToDeleteTrack playlist track ->
            ( { model | state = AskingToDeleteTrack playlist track }
            , Cmd.none
            )

        DeleteTrack playlistId trackUri ->
            ( { model | state = DeletingTrack }
            , deleteTrackFromPlaylist model playlistId trackUri
            )

        TrackDeleted playlistId (Ok playlists) ->
            { model | state = PlaylistSelection, playlists = playlists }
                |> update (SelectPlaylist playlistId)

        TrackDeleted _ (Err _) ->
            ( { model | state = Errored "Failed to delete track." }
            , Cmd.none
            )


setReferenceTimeToNow : Cmd Msg
setReferenceTimeToNow =
    Task.perform ReferenceTimeSet Time.now


fetchUser : AccessToken -> Cmd Msg
fetchUser accessToken =
    User.fetchData (Spotify.getRequest accessToken)
        |> Cmd.map UserMsg


fetchFavoriteTracks : AccessToken -> Cmd Msg
fetchFavoriteTracks accessToken =
    Track.fetchFavoriteTracks
        FavoriteTracksFetched
        (Spotify.getRequest accessToken)


fetchPlaylists : AccessToken -> Cmd Msg
fetchPlaylists accessToken =
    Track.fetchPlaylists (Spotify.get PlaylistsFetched accessToken)


fetchPlaylistTracks : Model -> Playlist -> Cmd Msg
fetchPlaylistTracks model playlist =
    Track.fetchPlaylistTracks
        PlaylistTracksFetched
        (Spotify.getRequest model.accessToken)
        model.referenceTime
        playlist
        model.favoriteTracks


deleteTrackFromPlaylist : Model -> PlaylistId -> TrackUri -> Cmd Msg
deleteTrackFromPlaylist model playlistId trackUri =
    Track.deleteTrackFromPlaylist
        (Spotify.delete (TrackDeleted playlistId) model.accessToken)
        model.user.id
        model.playlists
        playlistId
        trackUri


playlistsOwnedByUser : UserId -> List Playlist -> List Playlist
playlistsOwnedByUser userId =
    List.filter (\p -> p.ownerId == userId)



-- VIEW


view : Model -> Html Msg
view model =
    case model.state of
        Blank ->
            text ""

        Loading ->
            loader "Fetching data from Spotify…"

        LoadingPlaylists message ->
            div []
                [ mainNav model.user
                , mainContainer [ pageTitle, loaderBlock message ]
                ]

        PlaylistSelection ->
            div []
                [ mainNav model.user
                , mainContainer
                    [ pageTitle
                    , viewPlaylistSelectForm model.playlists
                    ]
                ]

        LoadingTracks ->
            div []
                [ mainNav model.user
                , mainContainer
                    [ pageTitle
                    , viewPlaylistSelectForm model.playlists
                    , loaderBlock "Fetching playlist tracks…"
                    ]
                ]

        PlaylistTracks playlist ->
            div []
                [ mainNav model.user
                , mainContainer
                    [ pageTitle
                    , viewPlaylistSelectForm model.playlists
                    , Track.viewPlaylistTracks AskToDeleteTrack playlist
                    ]
                ]

        DeletingTrack ->
            div []
                [ mainNav model.user
                , mainContainer [ pageTitle, loaderBlock "Deleting the track…" ]
                ]

        Errored message ->
            text ("An error occurred: " ++ message)

        AskingToDeleteTrack playlist track ->
            div []
                [ mainNav model.user
                , mainContainer
                    [ pageTitle
                    , viewConfirmDeleteTrack model playlist track
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
    nav
        [ class "ui fixed borderless secondary pointing nav menu" ]
        [ div
            [ class "ui container" ]
            [ div
                [ class "header item" ]
                [ User.view user ]
            ]
        ]


viewPlaylistSelectForm : List Playlist -> Html Msg
viewPlaylistSelectForm =
    Track.viewPlaylistSelectForm SelectPlaylist


viewConfirmDeleteTrack : Model -> Playlist -> Track -> Html Msg
viewConfirmDeleteTrack model playlist track =
    Track.viewConfirmDeleteTrack
        (confirm
            (DeleteTrack playlist.id track.uri)
            (SelectPlaylist playlist.id)
        )
        playlist
        track



-- SUBSCRIPTIONS


port accessToken : (String -> a) -> Sub a


subscriptions : Model -> Sub Msg
subscriptions model =
    accessToken LogIn
