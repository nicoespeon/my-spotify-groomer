module Playlist
    exposing
        ( Playlist
        , PlaylistId
        , SnapshotId
        , Msg
        , Model
        , emptyModel
        , update
        , fetchFavoriteTracks
        , view
        )

import Html exposing (Html, text, form, div, label, option, select, h2, i, p, strong, ul, li, button)
import Html.Attributes exposing (id, class, value, disabled, selected)
import Html.Events exposing (onInput, onClick)
import Http exposing (Error, Request)
import SemanticUI exposing (confirm, deleteButton, disabledDeleteButton, loaderBlock)
import Spotify exposing (Url, Offset, Limit, IsLocal)
import Task exposing (Task)
import Time exposing (Time)
import Track exposing (Track, TrackUri, PaginatedTracks)
import User exposing (UserId)


-- MODEL


type alias Model =
    { state : State
    , playlists : List Playlist
    , selectedPlaylist : Maybe Playlist
    , favoriteTrackUris : List TrackUri
    , isSelectingTracks : Bool
    }


type State
    = LoadingPlaylists
    | PlaylistSelection
    | LoadingTracks
    | PlaylistTracks
    | AskingToDeleteTracks Playlist
    | DeletingTracks
    | Errored String


type alias Playlist =
    { id : PlaylistId
    , ownerId : UserId
    , name : String
    , snapshotId : SnapshotId
    , tracksUrl : String
    , tracks : List Track
    }


type alias PlaylistId =
    String


type alias SnapshotId =
    String


emptyModel : Model
emptyModel =
    { state = LoadingPlaylists
    , playlists = []
    , selectedPlaylist = Nothing
    , favoriteTrackUris = []
    , isSelectingTracks = False
    }


type AllTracksSelectionInPlaylist
    = Selected
    | Unselected
    | Mix



-- UPDATE


type Msg
    = FavoriteTracksFetched (Result Error (List TrackUri))
    | PlaylistsFetched (Result Error (List Playlist))
    | SelectPlaylist PlaylistId
    | PlaylistTracksFetched (Result Error Playlist)
    | ToggleTrackDeletion Track
    | ToggleTracksDeletion
    | AskToDeleteTracks
    | DeleteTracks Playlist
    | TracksDeleted (Result Error Playlist)


update :
    Request (List Playlist)
    -> (Url -> Request PaginatedTracks)
    -> (PlaylistId -> SnapshotId -> List Track -> IsLocal -> Request SnapshotId)
    -> Time
    -> UserId
    -> Msg
    -> Model
    -> ( Model, Cmd Msg )
update getCurrentUserPlaylists getPlaylistTracks removeTracksFromPlaylist referenceTime userId msg model =
    case msg of
        FavoriteTracksFetched (Ok trackUris) ->
            ( { model | favoriteTrackUris = trackUris }, fetchPlaylists getCurrentUserPlaylists )

        FavoriteTracksFetched (Err _) ->
            ( { model | state = Errored "Failed to fetch user top tracks." }
            , Cmd.none
            )

        PlaylistsFetched (Ok playlists) ->
            ( { model
                | state = PlaylistSelection
                , playlists = playlistsOwnedByUser userId playlists
              }
            , Cmd.none
            )

        PlaylistsFetched (Err _) ->
            ( { model | state = Errored "Failed to fetch user playlists." }
            , Cmd.none
            )

        SelectPlaylist playlistId ->
            let
                cmd =
                    case selectedPlaylist playlistId model.playlists of
                        Just playlist ->
                            fetchPlaylistTracks
                                referenceTime
                                model.favoriteTrackUris
                                getPlaylistTracks
                                { playlist | tracks = [] }

                        Nothing ->
                            Cmd.none
            in
                ( { model | state = LoadingTracks }, cmd )

        PlaylistTracksFetched (Ok playlist) ->
            ( { model
                | state = PlaylistTracks
                , selectedPlaylist = Just playlist
                , isSelectingTracks = False
              }
            , Cmd.none
            )

        PlaylistTracksFetched (Err _) ->
            ( { model | state = Errored "Failed to fetch playlist tracks." }
            , Cmd.none
            )

        AskToDeleteTracks ->
            case model.selectedPlaylist of
                Just playlist ->
                    ( { model | state = AskingToDeleteTracks playlist }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        DeleteTracks playlist ->
            ( { model | state = DeletingTracks }
            , deleteTracksFromPlaylist
                (removeTracksFromPlaylist playlist.id playlist.snapshotId)
                playlist
            )

        TracksDeleted (Ok playlist) ->
            updatePlaylists model playlist
                |> update
                    getCurrentUserPlaylists
                    getPlaylistTracks
                    removeTracksFromPlaylist
                    referenceTime
                    userId
                    (SelectPlaylist playlist.id)

        TracksDeleted (Err _) ->
            ( { model | state = Errored "Failed to delete tracks." }, Cmd.none )

        ToggleTrackDeletion track ->
            ( toggleTrackDeletion model track, Cmd.none )

        ToggleTracksDeletion ->
            ( toggleTracksDeletion model, Cmd.none )


playlistsOwnedByUser : UserId -> List Playlist -> List Playlist
playlistsOwnedByUser userId =
    List.filter (\p -> p.ownerId == userId)


selectedPlaylist : PlaylistId -> List Playlist -> Maybe Playlist
selectedPlaylist playlistId =
    List.filter (\p -> p.id == playlistId)
        >> List.head


setTracksDeletion : Playlist -> Bool -> Playlist
setTracksDeletion playlist shouldBeDeleted =
    { playlist
        | tracks = List.map (Track.setDeletion shouldBeDeleted) playlist.tracks
    }


toggleTracksDeletion : Model -> Model
toggleTracksDeletion model =
    let
        isSelectingTracks =
            not model.isSelectingTracks
    in
        case model.selectedPlaylist of
            Just playlist ->
                { model
                    | isSelectingTracks = isSelectingTracks
                    , selectedPlaylist =
                        Just (setTracksDeletion playlist isSelectingTracks)
                }

            Nothing ->
                model


toggleTrackDeletion : Model -> Track -> Model
toggleTrackDeletion model trackToUpdate =
    case model.selectedPlaylist of
        Just playlist ->
            let
                selectedPlaylist =
                    toggleTrackDeletionInPlaylist playlist trackToUpdate

                isSelectingTracks =
                    if allTracksAreSelected selectedPlaylist then
                        True
                    else if allTracksAreUnselected selectedPlaylist then
                        False
                    else
                        model.isSelectingTracks
            in
                { model
                    | isSelectingTracks = isSelectingTracks
                    , selectedPlaylist =
                        Just selectedPlaylist
                }

        Nothing ->
            model


toggleTrackDeletionInPlaylist : Playlist -> Track -> Playlist
toggleTrackDeletionInPlaylist playlist trackToUpdate =
    { playlist
        | tracks =
            List.map
                (\track ->
                    if track == trackToUpdate then
                        Track.toggleDeletion track
                    else
                        track
                )
                playlist.tracks
    }


allTracksAreSelected : Playlist -> Bool
allTracksAreSelected playlist =
    List.all .shouldBeDeleted playlist.tracks


allTracksAreUnselected : Playlist -> Bool
allTracksAreUnselected playlist =
    List.all (\track -> not track.shouldBeDeleted) playlist.tracks


updatePlaylists : Model -> Playlist -> Model
updatePlaylists model newPlaylist =
    { model
        | playlists =
            List.map
                (\playlist ->
                    if playlist.id == newPlaylist.id then
                        newPlaylist
                    else
                        playlist
                )
                model.playlists
    }


fetchPlaylists : Request (List Playlist) -> Cmd Msg
fetchPlaylists getCurrentUserPlaylists =
    Http.send PlaylistsFetched getCurrentUserPlaylists


fetchFavoriteTracks : (Offset -> Limit -> Request (List TrackUri)) -> Cmd Msg
fetchFavoriteTracks getCurrentUserTopTracks =
    Track.fetchFavoriteTracks getCurrentUserTopTracks FavoriteTracksFetched


fetchPlaylistTracks :
    Time
    -> List TrackUri
    -> (Url -> Request PaginatedTracks)
    -> Playlist
    -> Cmd Msg
fetchPlaylistTracks referenceTime favoriteTrackUris getPlaylistTracks playlist =
    Track.fetchTracks
        PlaylistTracksFetched
        referenceTime
        favoriteTrackUris
        (\tracks -> Task.succeed { playlist | tracks = tracks })
        getPlaylistTracks
        playlist.tracksUrl


deleteTracksFromPlaylist :
    (List Track -> IsLocal -> Request SnapshotId)
    -> Playlist
    -> Cmd Msg
deleteTracksFromPlaylist removeTracksFromPlaylist playlist =
    let
        delete tracks isLocal =
            Http.toTask (removeTracksFromPlaylist tracks isLocal)
    in
        Task.attempt TracksDeleted <|
            Task.map2
                (\_ newSnapshotId -> { playlist | snapshotId = newSnapshotId })
                (delete (Track.localsToBeDeleted playlist.tracks) True)
                (delete (Track.notLocalsToBeDeleted playlist.tracks) False)



-- VIEW


view : Model -> Html Msg
view model =
    case model.state of
        LoadingPlaylists ->
            loaderBlock "Fetching your playlists…"

        PlaylistSelection ->
            viewPlaylistSelectForm model.playlists

        LoadingTracks ->
            div []
                [ viewPlaylistSelectForm model.playlists
                , loaderBlock "Fetching playlist tracks…"
                ]

        PlaylistTracks ->
            case model.selectedPlaylist of
                Just playlist ->
                    div []
                        [ viewPlaylistSelectForm model.playlists
                        , viewPlaylistTracks
                            playlist
                            model.isSelectingTracks
                        ]

                Nothing ->
                    viewPlaylistSelectForm model.playlists

        AskingToDeleteTracks playlist ->
            viewConfirmDeletion playlist

        DeletingTracks ->
            loaderBlock "Deleting the track…"

        Errored message ->
            text ("An error occurred: " ++ message)


viewPlaylistSelectForm : List Playlist -> Html Msg
viewPlaylistSelectForm playlists =
    let
        placeholderOption =
            option [ disabled True, selected True ] [ text "🎧 Select a playlist" ]

        playlistOptions =
            placeholderOption
                :: List.map
                    (\p -> option [ value p.id ] [ text p.name ])
                    playlists
    in
        form
            [ class "ui form" ]
            [ div
                [ class "field" ]
                [ label [] [ text "Which playlist would you like to groom?" ]
                , select
                    [ class "ui fluid dropdown", onInput SelectPlaylist ]
                    playlistOptions
                ]
            ]


viewPlaylistTracks : Playlist -> Bool -> Html Msg
viewPlaylistTracks playlist isSelectingTracks =
    let
        nbTracks =
            playlist.tracks |> List.length |> toString
    in
        div []
            [ h2
                [ class "ui section horizontal divider header" ]
                [ i [ class "music icon" ] [], text playlist.name ]
            , p
                []
                [ text "Here are the "
                , strong [] [ text (nbTracks ++ " songs ") ]
                , text "you don't listen much in this playlist:"
                ]
            , toggleSelectionButton isSelectingTracks
            , playlistDeleteButton playlist.tracks
            , div
                [ class "ui relaxed list" ]
                (List.map viewTrack playlist.tracks)
            ]


playlistDeleteButton : List Track -> Html Msg
playlistDeleteButton tracks =
    let
        nbSelectedTracks =
            tracks |> Track.toBeDeleted |> List.length |> toString
    in
        case nbSelectedTracks of
            "0" ->
                disabledDeleteButton "Select songs to delete"

            "1" ->
                deleteButton
                    AskToDeleteTracks
                    "Delete the selected song"

            _ ->
                deleteButton
                    AskToDeleteTracks
                    ("Delete the " ++ nbSelectedTracks ++ " selected songs")


toggleSelectionButton : Bool -> Html Msg
toggleSelectionButton isSelectingTracks =
    let
        labelText =
            if isSelectingTracks then
                "Unselect all"
            else
                "Select all"
    in
        button
            [ class "ui button", onClick ToggleTracksDeletion ]
            [ text labelText ]


viewTrack : Track -> Html Msg
viewTrack track =
    Track.view track (ToggleTrackDeletion track)


viewConfirmDeletion : Playlist -> Html Msg
viewConfirmDeletion playlist =
    let
        selectedTracks =
            Track.toBeDeleted playlist.tracks

        selectedTracksNames =
            selectedTracks |> List.map .name

        nbSelectedTracks =
            selectedTracks |> List.length |> toString

        confirmDeletion =
            confirm
                (DeleteTracks playlist)
                (SelectPlaylist playlist.id)
    in
        if nbSelectedTracks == "1" then
            confirmDeletion
                (div []
                    [ text "Do you really want to delete "
                    , strong [] [ text (List.foldr (++) "" selectedTracksNames) ]
                    , text " from "
                    , strong [] [ text playlist.name ]
                    , text "?"
                    ]
                )
                "Yes, delete it"
                "No, keep it"
        else
            confirmDeletion
                (div []
                    [ p
                        []
                        [ text "Do you really want to delete these "
                        , strong [] [ text nbSelectedTracks ]
                        , text " tracks from "
                        , strong [] [ text playlist.name ]
                        , text "?"
                        ]
                    , ul
                        [ class "ui list" ]
                        (List.map
                            (\name -> li [] [ text name ])
                            selectedTracksNames
                        )
                    ]
                )
                "Yes, delete them"
                "No, keep them"
