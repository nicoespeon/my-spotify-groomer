module Track exposing (Track, Msg, Model, emptyModel, update, fetchFavoriteTracks, view)

import Date exposing (Date)
import Html exposing (Html, text, form, div, label, option, select, h2, i, p, strong)
import Html.Attributes exposing (class, value, disabled, selected)
import Html.Events exposing (onInput)
import Http exposing (Error, Request)
import Json.Decode as Decode exposing (Decoder, at, string, bool)
import Json.Encode as Encode
import SemanticUI exposing (confirm, disabledDeleteButton, deleteButton, loaderBlock)
import Task exposing (Task)
import Time exposing (Time)
import User exposing (UserId)


-- MODEL


type alias Model =
    { state : State
    , playlists : List Playlist
    , favoriteTrackUris : List TrackUri
    }


type State
    = LoadingPlaylists
    | PlaylistSelection
    | LoadingTracks
    | PlaylistTracks Playlist
    | AskingToDeleteTrack Playlist Track
    | DeletingTrack
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
    , favoriteTrackUris = []
    }



-- UPDATE


type Msg
    = FavoriteTracksFetched (Result Error (List TrackUri))
    | PlaylistsFetched (Result Error (List Playlist))
    | SelectPlaylist PlaylistId
    | PlaylistTracksFetched (Result Error Playlist)
    | AskToDeleteTrack Playlist Track
    | DeleteTrack PlaylistId TrackUri
    | TrackDeleted PlaylistId (Result Error (List Playlist))


update :
    (String -> Decoder (List Playlist) -> Request (List Playlist))
    -> (String -> Decoder PaginatedTracks -> Request PaginatedTracks)
    -> (String -> Encode.Value -> Decoder (List Playlist) -> Request (List Playlist))
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
            , deleteTrackFromPlaylist
                delete
                userId
                model.playlists
                playlistId
                trackUri
            )

        TrackDeleted playlistId (Ok playlists) ->
            { model | playlists = playlists }
                |> update
                    fetch
                    fetchPaginatedTracks
                    delete
                    referenceTime
                    userId
                    (SelectPlaylist playlistId)

        TrackDeleted _ (Err _) ->
            ( { model | state = Errored "Failed to delete track." }, Cmd.none )


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
            (Decode.map4 Track
                (at [ "track", "uri" ] string)
                (at [ "track", "name" ] string)
                (at [ "is_local" ] bool)
                (at [ "added_at" ] decodeDate)
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


deleteTrackFromPlaylist :
    (String -> Encode.Value -> Decoder (List Playlist) -> Request (List Playlist))
    -> UserId
    -> List Playlist
    -> PlaylistId
    -> TrackUri
    -> Cmd Msg
deleteTrackFromPlaylist delete userId playlists playlistId trackUri =
    let
        url =
            "/users/" ++ userId ++ "/playlists/" ++ playlistId ++ "/tracks"

        body =
            Encode.object
                [ ( "tracks"
                  , Encode.list
                        [ Encode.object
                            [ ( "uri", Encode.string trackUri ) ]
                        ]
                  )
                ]

        playlistWithoutTrackDecoder =
            Decode.succeed (playlistsWithoutTrack trackUri playlists)
    in
        Http.send
            (TrackDeleted playlistId)
            (delete url body playlistWithoutTrackDecoder)



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

        PlaylistTracks selectedPlaylist ->
            div []
                [ viewPlaylistSelectForm model.playlists
                , viewPlaylistTracks selectedPlaylist
                ]

        AskingToDeleteTrack playlist track ->
            viewConfirmDeleteTrack playlist track

        DeletingTrack ->
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
                , select [ class "ui fluid dropdown", onInput SelectPlaylist ] playlistOptions
                ]
            ]


viewPlaylistTracks : Playlist -> Html Msg
viewPlaylistTracks playlist =
    div []
        [ h2
            [ class "ui section horizontal divider header" ]
            [ i [ class "music icon" ] [], text playlist.name ]
        , p
            []
            [ text "Here are the "
            , strong []
                [ text
                    ((playlist.tracks |> List.length |> toString) ++ " songs ")
                ]
            , text "you don't listen much in this playlist:"
            ]
        , div
            [ class "ui divided relaxed list" ]
            (List.map (viewTrack (AskToDeleteTrack playlist)) playlist.tracks)
        ]


viewTrack : (Track -> a) -> Track -> Html a
viewTrack onDeleteButtonMsg track =
    div [ class "item" ]
        [ div
            [ class "right floated content" ]
            [ viewDeleteTrackButton onDeleteButtonMsg track ]
        , div
            [ class "content" ]
            [ p [ class "header" ] [ text track.name ] ]
        ]


viewDeleteTrackButton : (Track -> a) -> Track -> Html a
viewDeleteTrackButton onDeleteButtonMsg track =
    if track.isLocal then
        disabledDeleteButton "I can't delete local files from your playlist (yet)"
    else
        deleteButton (onDeleteButtonMsg track)


viewConfirmDeleteTrack : Playlist -> Track -> Html Msg
viewConfirmDeleteTrack playlist track =
    let
        message =
            div []
                [ text "Do you really want to delete "
                , strong [] [ text track.name ]
                , text " from "
                , strong [] [ text playlist.name ]
                , text "?"
                ]
    in
        confirm
            (DeleteTrack playlist.id track.uri)
            (SelectPlaylist playlist.id)
            message
            "Yes, delete it"
            "No, keep the track"
