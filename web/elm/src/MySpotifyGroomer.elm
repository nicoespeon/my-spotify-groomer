port module MySpotifyGroomer exposing (main)

import Html exposing (Html, program, h1, div, text, nav)
import Html.Attributes exposing (class)
import Http exposing (Error)
import Navigation exposing (load)
import SemanticUI exposing (loader, loaderBlock)
import Spotify exposing (AccessToken, get, getRequest, delete)
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
    }


type State
    = Blank
    | Loading
    | Errored String
    | LoadingPlaylists String
    | PlaylistSelection
    | LoadingTracks
    | PlaylistTracks Playlist
    | DeletingTrack


init : ( Model, Cmd Msg )
init =
    ( emptyModel, Cmd.none )


emptyModel : Model
emptyModel =
    { accessToken = ""
    , state = Blank
    , user = User "" "" Nothing
    , playlists = []
    , favoriteTracks = []
    }



-- UPDATE


type Msg
    = LogIn AccessToken
    | UserFetched (Result Error User)
    | FavoriteTracksFetched (Result Error (List TrackUri))
    | PlaylistsFetched (Result Error (List Playlist))
    | SelectPlaylist PlaylistId
    | PlaylistTracksFetched (Result Error Playlist)
    | DeleteTrack PlaylistId TrackUri
    | TrackDeleted (Result Error (List Playlist))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LogIn accessToken ->
            ( { model | state = Loading, accessToken = accessToken }
            , fetchUser accessToken
            )

        UserFetched (Ok user) ->
            ( { model
                | state = LoadingPlaylists "Fetching your favorite tracks…"
                , user = user
              }
            , fetchFavoriteTracks model.accessToken
            )

        UserFetched (Err _) ->
            ( { model | state = Errored "Failed to fetch user data." }
            , load "/login"
            )

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
                    , fetchPlaylistTracks model.accessToken playlist model.favoriteTracks
                    )

                Nothing ->
                    ( model, Cmd.none )

        PlaylistTracksFetched (Ok playlist) ->
            ( { model | state = PlaylistTracks playlist }, Cmd.none )

        PlaylistTracksFetched (Err _) ->
            ( { model | state = Errored "Failed to fetch playlist tracks." }
            , Cmd.none
            )

        DeleteTrack playlistId trackUri ->
            ( { model | state = DeletingTrack }
            , deleteTrackFromPlaylist model playlistId trackUri
            )

        TrackDeleted (Ok playlists) ->
            ( { model | state = PlaylistSelection, playlists = playlists }
            , Cmd.none
            )

        TrackDeleted (Err _) ->
            ( { model | state = Errored "Failed to delete track." }
            , Cmd.none
            )


fetchUser : AccessToken -> Cmd Msg
fetchUser accessToken =
    User.fetchData (Spotify.get UserFetched accessToken)


fetchFavoriteTracks : AccessToken -> Cmd Msg
fetchFavoriteTracks accessToken =
    Track.fetchFavoriteTracks (Spotify.get FavoriteTracksFetched accessToken)


fetchPlaylists : AccessToken -> Cmd Msg
fetchPlaylists accessToken =
    Track.fetchPlaylists (Spotify.get PlaylistsFetched accessToken)


fetchPlaylistTracks : AccessToken -> Playlist -> List TrackUri -> Cmd Msg
fetchPlaylistTracks accessToken playlist favoriteTracks =
    Track.fetchPlaylistTracks
        PlaylistTracksFetched
        (Spotify.getRequest accessToken)
        playlist
        favoriteTracks


deleteTrackFromPlaylist : Model -> PlaylistId -> TrackUri -> Cmd Msg
deleteTrackFromPlaylist model playlistId trackUri =
    Track.deleteTrackFromPlaylist
        (Spotify.delete TrackDeleted model.accessToken)
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
                    , Track.viewPlaylistSelectForm SelectPlaylist model.playlists
                    ]
                ]

        LoadingTracks ->
            div []
                [ mainNav model.user
                , mainContainer
                    [ pageTitle
                    , Track.viewPlaylistSelectForm SelectPlaylist model.playlists
                    , loaderBlock "Fetching playlist tracks…"
                    ]
                ]

        PlaylistTracks playlist ->
            div []
                [ mainNav model.user
                , mainContainer
                    [ pageTitle
                    , Track.viewPlaylistSelectForm SelectPlaylist model.playlists
                    , Track.viewPlaylistTracks DeleteTrack playlist
                    ]
                ]

        DeletingTrack ->
            div []
                [ mainNav model.user
                , mainContainer [ pageTitle, loaderBlock "Deleting the track…" ]
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
