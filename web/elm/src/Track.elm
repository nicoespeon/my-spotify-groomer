module Track exposing (Track, Msg, Model, emptyModel, update, fetchFavoriteTracks, view)

import Date exposing (Date)
import Html exposing (Html, text, form, div, label, option, select, h2, i, p, strong, input, ul, li)
import Html.Attributes exposing (id, class, value, disabled, selected, checked, type_, for, name)
import Html.Events exposing (onInput, onClick)
import Http exposing (Error, Request)
import Json.Decode as Decode exposing (Decoder, at, string, bool)
import Json.Encode as Encode
import SemanticUI exposing (confirm, deleteButton, disabledDeleteButton, loaderBlock)
import Task exposing (Task)
import Time exposing (Time)
import User exposing (UserId)


-- MODEL


type alias Model =
    { state : State
    , playlists : List Playlist
    , selectedPlaylist : Maybe Playlist
    , favoriteTrackUris : List TrackUri
    }


type State
    = LoadingPlaylists
    | PlaylistSelection
    | LoadingTracks
    | PlaylistTracks Time
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


type alias Track =
    { uri : TrackUri
    , name : String
    , isLocal : Bool
    , addedAt : Date
    , shouldBeDeleted : Bool
    , position : Int
    }


type alias TrackUri =
    String


type alias PaginatedTracks =
    { tracks : List Track
    , next : Maybe String
    }


emptyModel : Model
emptyModel =
    { state = LoadingPlaylists
    , playlists = []
    , selectedPlaylist = Nothing
    , favoriteTrackUris = []
    }



-- UPDATE


type Msg
    = FavoriteTracksFetched (Result Error (List TrackUri))
    | PlaylistsFetched (Result Error (List Playlist))
    | SelectPlaylist PlaylistId
    | PlaylistTracksFetched (Result Error Playlist)
    | ToggleTrackDeletion Track
    | AskToDeleteTracks
    | DeleteTracks Playlist
    | TracksDeleted (Result Error Playlist)


update :
    (String -> Decoder (List Playlist) -> Request (List Playlist))
    -> (String -> Decoder PaginatedTracks -> Request PaginatedTracks)
    -> (String -> Encode.Value -> Decoder SnapshotId -> Request SnapshotId)
    -> Time
    -> UserId
    -> Msg
    -> Model
    -> ( Model, Cmd Msg )
update fetch fetchPaginatedTracks delete referenceTime userId msg model =
    case msg of
        FavoriteTracksFetched (Ok trackUris) ->
            ( { model | favoriteTrackUris = trackUris }, fetchPlaylists fetch )

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
                                fetchPaginatedTracks
                                { playlist | tracks = [] }

                        Nothing ->
                            Cmd.none
            in
                ( { model | state = LoadingTracks }, cmd )

        PlaylistTracksFetched (Ok playlist) ->
            ( { model
                | state = PlaylistTracks referenceTime
                , selectedPlaylist = Just playlist
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
            , deleteTracksFromPlaylist delete userId playlist
            )

        TracksDeleted (Ok playlist) ->
            updatePlaylists model playlist
                |> update
                    fetch
                    fetchPaginatedTracks
                    delete
                    referenceTime
                    userId
                    (SelectPlaylist playlist.id)

        TracksDeleted (Err _) ->
            ( { model | state = Errored "Failed to delete tracks." }, Cmd.none )

        ToggleTrackDeletion track ->
            let
                newModel =
                    case model.selectedPlaylist of
                        Just playlist ->
                            { model
                                | selectedPlaylist =
                                    Just (toggleTrackDeletionInPlaylist track playlist)
                            }

                        Nothing ->
                            model
            in
                ( newModel, Cmd.none )


playlistsOwnedByUser : UserId -> List Playlist -> List Playlist
playlistsOwnedByUser userId =
    List.filter (\p -> p.ownerId == userId)


selectedPlaylist : PlaylistId -> List Playlist -> Maybe Playlist
selectedPlaylist playlistId =
    List.filter (\p -> p.id == playlistId)
        >> List.head


playlistsWithoutTrack : TrackUri -> List Playlist -> List Playlist
playlistsWithoutTrack trackUri =
    List.map
        (\playlist ->
            { playlist
                | tracks =
                    List.filter
                        (\track -> track.uri /= trackUri)
                        playlist.tracks
            }
        )


toggleTrackDeletionInPlaylist : Track -> Playlist -> Playlist
toggleTrackDeletionInPlaylist trackToUpdate playlist =
    { playlist
        | tracks =
            List.map
                (\track ->
                    if track == trackToUpdate then
                        toggleTrackDeletion track
                    else
                        track
                )
                playlist.tracks
    }


toggleTrackDeletion : Track -> Track
toggleTrackDeletion track =
    { track | shouldBeDeleted = not track.shouldBeDeleted }


tracksToBeDeleted : List Track -> List Track
tracksToBeDeleted =
    List.filter .shouldBeDeleted


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


playlistsDecoder : Decoder (List Playlist)
playlistsDecoder =
    at [ "items" ]
        (Decode.list
            (Decode.map6 Playlist
                (at [ "id" ] string)
                (at [ "owner", "id" ] string)
                (at [ "name" ] string)
                snapshotIdDecoder
                (at [ "tracks", "href" ] string)
                (Decode.succeed [])
            )
        )


snapshotIdDecoder : Decoder SnapshotId
snapshotIdDecoder =
    at [ "snapshot_id" ] string


fetchPlaylists : (String -> Decoder (List Playlist) -> Request (List Playlist)) -> Cmd Msg
fetchPlaylists fetch =
    Http.send
        PlaylistsFetched
        (fetch "/me/playlists?fields=items(id,owner.id,name,tracks.href,snapshot_id)&limit=50" playlistsDecoder)


trackUrisDecoder : Decoder (List TrackUri)
trackUrisDecoder =
    at [ "items" ]
        (Decode.list (at [ "uri" ] string))


fetchFavoriteTracks :
    (String -> Decoder (List TrackUri) -> Request (List TrackUri))
    -> Cmd Msg
fetchFavoriteTracks fetch =
    let
        -- Spotify limits number of top tracks that can be fetched to 50.
        -- But we can hack a bit and retrieve up to 99 using 49 as the offset.
        -- Offset of 50+ returns no track.
        -- short_term = last 4 weeks (recent listenings)
        fetchShortTermFirst50TopTracks =
            fetch "/me/top/tracks?time_range=short_term&offset=0&limit=50" trackUrisDecoder

        fetchShortTerm49To99TopTracks =
            fetch "/me/top/tracks?time_range=short_term&offset=49&limit=50" trackUrisDecoder
    in
        Task.attempt
            FavoriteTracksFetched
            (getTrackUris fetchShortTermFirst50TopTracks []
                |> Task.andThen (getTrackUris fetchShortTerm49To99TopTracks)
            )


getTrackUris : Request (List TrackUri) -> List TrackUri -> Task Error (List TrackUri)
getTrackUris fetchTrackUris trackUris =
    Http.toTask fetchTrackUris
        |> Task.andThen (Task.succeed << List.append trackUris)


tracksDecoder : Decoder (List Track)
tracksDecoder =
    at [ "items" ]
        (Decode.list
            (Decode.map6 Track
                (at [ "track", "uri" ] string)
                (at [ "track", "name" ] string)
                (at [ "is_local" ] bool)
                (at [ "added_at" ] decodeDate)
                -- We don't want track to be selected by default
                (Decode.succeed False)
                -- Position in the playlist is computed when we append the track
                (Decode.succeed 0)
            )
        )


decodeDate : Decoder Date
decodeDate =
    string
        |> Decode.andThen
            (\val ->
                case Date.fromString val of
                    Ok date ->
                        Decode.succeed date

                    Err err ->
                        Decode.fail err
            )


paginatedTracksDecoder : Decoder PaginatedTracks
paginatedTracksDecoder =
    Decode.map2 PaginatedTracks
        tracksDecoder
        (Decode.maybe (at [ "next" ] string))


fetchPlaylistTracks :
    (String -> Decoder PaginatedTracks -> Request PaginatedTracks)
    -> Playlist
    -> Cmd Msg
fetchPlaylistTracks fetch playlist =
    let
        url =
            playlist.tracksUrl ++ "?fields=items(track.name,track.uri,is_local,added_at),next"
    in
        Task.attempt
            PlaylistTracksFetched
            (fetchPlaylistTracksWithUrl fetch url playlist)


fetchPlaylistTracksWithUrl :
    (String -> Decoder PaginatedTracks -> Request PaginatedTracks)
    -> String
    -> Playlist
    -> Task Error Playlist
fetchPlaylistTracksWithUrl fetch url playlist =
    Http.toTask (fetch url paginatedTracksDecoder)
        |> Task.andThen
            (\pt ->
                let
                    fetchAgain =
                        fetchPlaylistTracksWithUrl fetch
                in
                    case pt.next of
                        Just nextUrl ->
                            addTracksToPlaylist playlist pt.tracks
                                |> Task.andThen (fetchAgain nextUrl)

                        Nothing ->
                            addTracksToPlaylist playlist pt.tracks
            )


addTracksToPlaylist : Playlist -> List Track -> Task Error Playlist
addTracksToPlaylist playlist tracks =
    let
        newTracks =
            tracks
                |> List.append playlist.tracks
                |> List.indexedMap (\i track -> { track | position = i })
    in
        Task.succeed { playlist | tracks = newTracks }


isTrackNotListenedAnymore : Time -> List TrackUri -> Track -> Bool
isTrackNotListenedAnymore referenceTime favoriteTrackUris track =
    not (List.member track.uri favoriteTrackUris)
        && hasBeenAddedNDaysBefore 14 referenceTime track


hasBeenAddedNDaysBefore : Float -> Time -> Track -> Bool
hasBeenAddedNDaysBefore days referenceTime track =
    let
        referenceTimeInMs =
            Time.inMilliseconds referenceTime

        msForNDays =
            days * 24 * 60 * 60 * 1000

        trackAddedAtInMs =
            track.addedAt
                |> Date.toTime
                |> Time.inMilliseconds
    in
        trackAddedAtInMs < (referenceTimeInMs - msForNDays)


deleteTracksFromPlaylist :
    (String -> Encode.Value -> Decoder SnapshotId -> Request SnapshotId)
    -> UserId
    -> Playlist
    -> Cmd Msg
deleteTracksFromPlaylist deleteRequest userId playlist =
    let
        url =
            "/users/" ++ userId ++ "/playlists/" ++ playlist.id ++ "/tracks"

        localTracksRequestBody =
            playlist.tracks
                |> List.filter .isLocal
                |> tracksToBeDeleted
                |> localTracksDeleteRequestBody playlist.snapshotId

        notLocalTracksRequestBody =
            playlist.tracks
                |> List.filter (not << .isLocal)
                |> tracksToBeDeleted
                |> notLocalTracksDeleteRequestBody

        delete body =
            Http.toTask
                (deleteRequest url body snapshotIdDecoder)
    in
        Task.attempt TracksDeleted <|
            Task.map2
                (\_ newSnapshotId -> { playlist | snapshotId = newSnapshotId })
                (delete localTracksRequestBody)
                (delete notLocalTracksRequestBody)


notLocalTracksDeleteRequestBody : List Track -> Encode.Value
notLocalTracksDeleteRequestBody tracks =
    Encode.object
        [ ( "tracks"
          , tracks
                |> List.map
                    (\track ->
                        Encode.object
                            [ ( "uri", Encode.string track.uri ) ]
                    )
                |> Encode.list
          )
        ]


localTracksDeleteRequestBody : SnapshotId -> List Track -> Encode.Value
localTracksDeleteRequestBody snapshotId tracks =
    if List.length tracks > 0 then
        Encode.object
            [ ( "positions"
              , tracks
                    |> List.map .position
                    |> List.map Encode.int
                    |> Encode.list
              )
            , ( "snapshot_id", Encode.string snapshotId )
            ]
    else
        Encode.object
            [ ( "tracks", Encode.list [] ) ]



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

        PlaylistTracks referenceTime ->
            case model.selectedPlaylist of
                Just playlist ->
                    div []
                        [ viewPlaylistSelectForm model.playlists
                        , viewPlaylistNotListenedTracks
                            playlist
                            referenceTime
                            model.favoriteTrackUris
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


viewPlaylistNotListenedTracks : Playlist -> Time -> List TrackUri -> Html Msg
viewPlaylistNotListenedTracks playlist referenceTime favoriteTrackUris =
    let
        tracks =
            playlist.tracks
                |> List.filter (isTrackNotListenedAnymore referenceTime favoriteTrackUris)

        nbTracks =
            tracks |> List.length |> toString
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
            , playlistDeleteButton tracks
            , div
                [ class "ui relaxed list" ]
                (List.map viewTrack tracks)
            ]


playlistDeleteButton : List Track -> Html Msg
playlistDeleteButton tracks =
    let
        nbSelectedTracks =
            tracks |> tracksToBeDeleted |> List.length |> toString
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


viewTrack : Track -> Html Msg
viewTrack track =
    div [ class "item" ]
        [ div
            [ class "ui checkbox" ]
            [ input
                [ type_ "checkbox"
                , name track.uri
                , id track.uri
                , checked track.shouldBeDeleted
                , onClick (ToggleTrackDeletion track)
                ]
                []
            , label [ for track.uri ] [ text track.name ]
            ]
        ]


viewConfirmDeletion : Playlist -> Html Msg
viewConfirmDeletion playlist =
    let
        selectedTracks =
            tracksToBeDeleted playlist.tracks

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
