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
    | PlaylistTracks
    | AskingToDeleteTracks Playlist
    | DeletingTracks
    | Errored String


type alias Playlist =
    { id : PlaylistId
    , ownerId : UserId
    , name : String
    , tracksUrl : String
    , tracks : List Track
    }


type alias PlaylistId =
    String


type alias Track =
    { uri : TrackUri
    , name : String
    , isLocal : Bool
    , addedAt : Date
    , shouldBeDeleted : Bool
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
    | TracksDeleted (Result Error PlaylistId)


update :
    (String -> Decoder (List Playlist) -> Request (List Playlist))
    -> (String -> Decoder PaginatedTracks -> Request PaginatedTracks)
    -> (String -> Encode.Value -> Decoder PlaylistId -> Request PlaylistId)
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
                                referenceTime
                                playlist
                                model.favoriteTrackUris

                        Nothing ->
                            Cmd.none
            in
                ( { model | state = LoadingTracks }, cmd )

        PlaylistTracksFetched (Ok playlist) ->
            ( { model
                | state = PlaylistTracks
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

        TracksDeleted (Ok playlistId) ->
            update
                fetch
                fetchPaginatedTracks
                delete
                referenceTime
                userId
                (SelectPlaylist playlistId)
                model

        TracksDeleted (Err _) ->
            ( { model | state = Errored "Failed to delete track." }, Cmd.none )

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


playlistsDecoder : Decoder (List Playlist)
playlistsDecoder =
    at [ "items" ]
        (Decode.list
            (Decode.map5 Playlist
                (at [ "id" ] string)
                (at [ "owner", "id" ] string)
                (at [ "name" ] string)
                (at [ "tracks", "href" ] string)
                (Decode.succeed [])
            )
        )


fetchPlaylists : (String -> Decoder (List Playlist) -> Request (List Playlist)) -> Cmd Msg
fetchPlaylists fetch =
    Http.send
        PlaylistsFetched
        (fetch "/me/playlists?fields=items(id,owner.id,name,tracks.href)&limit=50" playlistsDecoder)


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
            (Decode.map5 Track
                (at [ "track", "uri" ] string)
                (at [ "track", "name" ] string)
                (at [ "is_local" ] bool)
                (at [ "added_at" ] decodeDate)
                (Decode.succeed False)
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
    -> Time
    -> Playlist
    -> List TrackUri
    -> Cmd Msg
fetchPlaylistTracks fetch referenceTime playlist favoriteTrackUris =
    let
        url =
            playlist.tracksUrl ++ "?fields=items(track.name,track.uri,is_local,added_at),next"
    in
        Task.attempt
            PlaylistTracksFetched
            (fetchPlaylistTracksWithUrl fetch referenceTime favoriteTrackUris url playlist)


fetchPlaylistTracksWithUrl :
    (String -> Decoder PaginatedTracks -> Request PaginatedTracks)
    -> Time
    -> List TrackUri
    -> String
    -> Playlist
    -> Task Error Playlist
fetchPlaylistTracksWithUrl fetch referenceTime favoriteTrackUris url playlist =
    Http.toTask (fetch url paginatedTracksDecoder)
        |> Task.andThen
            (\pt ->
                let
                    addTracks =
                        addTracksToPlaylist
                            referenceTime
                            playlist
                            favoriteTrackUris

                    fetchAgain =
                        fetchPlaylistTracksWithUrl
                            fetch
                            referenceTime
                            favoriteTrackUris
                in
                    case pt.next of
                        Just nextUrl ->
                            addTracks pt.tracks
                                |> Task.andThen (fetchAgain nextUrl)

                        Nothing ->
                            addTracks pt.tracks
            )


addTracksToPlaylist : Time -> Playlist -> List TrackUri -> List Track -> Task Error Playlist
addTracksToPlaylist referenceTime playlist favoriteTrackUris tracks =
    let
        newTracks =
            playlist.tracks
                |> List.append tracks
                |> List.filter (isTrackNotListenedAnymore referenceTime favoriteTrackUris)
    in
        Task.succeed { playlist | tracks = newTracks }


isTrackNotListenedAnymore : Time -> List TrackUri -> Track -> Bool
isTrackNotListenedAnymore referenceTime favoriteTrackUris track =
    not (List.member track.uri favoriteTrackUris)
        && hasBeenCreated7DaysBefore referenceTime track


hasBeenCreated7DaysBefore : Time -> Track -> Bool
hasBeenCreated7DaysBefore referenceTime track =
    let
        referenceTimeInMs =
            Time.inMilliseconds referenceTime

        msFor7Days =
            7 * 24 * 60 * 60 * 1000

        trackAddedAtInMs =
            track.addedAt
                |> Date.toTime
                |> Time.inMilliseconds
    in
        trackAddedAtInMs < (referenceTimeInMs - msFor7Days)


deleteTracksFromPlaylist :
    (String -> Encode.Value -> Decoder PlaylistId -> Request PlaylistId)
    -> UserId
    -> Playlist
    -> Cmd Msg
deleteTracksFromPlaylist delete userId playlist =
    let
        tracksToDelete =
            tracksToBeDeleted playlist.tracks

        url =
            "/users/" ++ userId ++ "/playlists/" ++ playlist.id ++ "/tracks"

        body =
            Encode.object
                [ ( "tracks"
                  , tracksToDelete
                        |> List.map
                            (\track ->
                                Encode.object
                                    [ ( "uri", Encode.string track.uri ) ]
                            )
                        |> Encode.list
                  )
                ]
    in
        Http.send
            TracksDeleted
            (delete url body (Decode.succeed playlist.id))



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
                        , viewPlaylistTracks playlist
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


viewPlaylistTracks : Playlist -> Html Msg
viewPlaylistTracks playlist =
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
            , playlistDeleteButton playlist.tracks
            , div
                [ class "ui relaxed list" ]
                (List.map viewTrack playlist.tracks)
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
    if track.isLocal then
        div [ class "item" ]
            [ div
                [ class "ui disabled checkbox" ]
                [ input
                    [ type_ "checkbox"
                    , name track.uri
                    , id track.uri
                    , disabled True
                    ]
                    []
                , label
                    [ for track.uri ]
                    [ text track.name
                    , strong [] [ text " > Can't delete local files (yet)" ]
                    ]
                ]
            ]
    else
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
