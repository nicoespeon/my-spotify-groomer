module Track
    exposing
        ( Track
        , TrackUri
        , Playlist
        , PlaylistId
        , deleteTrackFromPlaylist
        , fetchFavoriteTracks
        , fetchPlaylists
        , fetchPlaylistTracks
        , selectedPlaylist
        , viewPlaylistSelectForm
        , viewPlaylistTracks
        )

import Html exposing (Html, text, form, div, label, option, select, h2, i, p)
import Html.Attributes exposing (class, value, disabled, selected)
import Html.Events exposing (onInput)
import Http exposing (Error, Request)
import Json.Decode as Decode exposing (Decoder, at, string, bool, map2, map3, map5, succeed)
import Json.Encode as Encode
import SemanticUI exposing (disabledDeleteButton, deleteButton)
import Task exposing (Task)
import User exposing (UserId)


-- MODEL


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
    }


type alias TrackUri =
    String


type alias PaginatedTracks =
    { tracks : List Track
    , next : Maybe String
    }



-- UPDATE


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
            (map5 Playlist
                (at [ "id" ] string)
                (at [ "owner", "id" ] string)
                (at [ "name" ] string)
                (at [ "tracks", "href" ] string)
                (succeed [])
            )
        )


fetchPlaylists : (String -> Decoder (List Playlist) -> Cmd a) -> Cmd a
fetchPlaylists fetch =
    fetch "/me/playlists?fields=items(id,owner.id,name,tracks.href)&limit=50" playlistsDecoder


trackUrisDecoder : Decoder (List TrackUri)
trackUrisDecoder =
    at [ "items" ]
        (Decode.list (at [ "uri" ] string))


fetchFavoriteTracks : (String -> Decoder (List TrackUri) -> Cmd a) -> Cmd a
fetchFavoriteTracks fetch =
    fetch "/me/top/tracks?time_range=short_term&limit=100" trackUrisDecoder


tracksDecoder : Decoder (List Track)
tracksDecoder =
    at [ "items" ]
        (Decode.list
            (map3 Track
                (at [ "track", "uri" ] string)
                (at [ "track", "name" ] string)
                (at [ "is_local" ] bool)
            )
        )


paginatedTracksDecoder : Decoder PaginatedTracks
paginatedTracksDecoder =
    map2 PaginatedTracks
        tracksDecoder
        (Decode.maybe (at [ "next" ] string))


fetchPlaylistTracks :
    (Result Error Playlist -> a)
    -> (String -> Decoder PaginatedTracks -> Request PaginatedTracks)
    -> Playlist
    -> List TrackUri
    -> Cmd a
fetchPlaylistTracks msg fetch playlist favoriteTrackUris =
    let
        url =
            playlist.tracksUrl ++ "?fields=items(track.name,track.uri,is_local),next"
    in
        Task.attempt msg (fetchPlaylistTracksWithUrl fetch favoriteTrackUris url playlist)


fetchPlaylistTracksWithUrl :
    (String -> Decoder PaginatedTracks -> Request PaginatedTracks)
    -> List TrackUri
    -> String
    -> Playlist
    -> Task Error Playlist
fetchPlaylistTracksWithUrl fetch favoriteTrackUris url playlist =
    Http.toTask (fetch url paginatedTracksDecoder)
        |> Task.andThen
            (\pt ->
                let
                    addTracks =
                        addTracksToPlaylist playlist favoriteTrackUris

                    fetchAgain =
                        fetchPlaylistTracksWithUrl fetch favoriteTrackUris
                in
                    case pt.next of
                        Just nextUrl ->
                            addTracks pt.tracks
                                |> Task.andThen (fetchAgain nextUrl)

                        Nothing ->
                            addTracks pt.tracks
            )


addTracksToPlaylist : Playlist -> List TrackUri -> List Track -> Task Error Playlist
addTracksToPlaylist playlist favoriteTrackUris tracks =
    let
        newTracks =
            playlist.tracks
                |> List.append tracks
                |> List.filter (\track -> not (List.member track.uri favoriteTrackUris))
    in
        Task.succeed { playlist | tracks = newTracks }


deleteTrackFromPlaylist :
    (String -> Encode.Value -> Decoder (List Playlist) -> Cmd a)
    -> UserId
    -> List Playlist
    -> PlaylistId
    -> TrackUri
    -> Cmd a
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
            succeed (playlistsWithoutTrack trackUri playlists)
    in
        delete url body playlistWithoutTrackDecoder



-- VIEW


viewPlaylistSelectForm : (String -> a) -> List Playlist -> Html a
viewPlaylistSelectForm onInputMsg playlists =
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
                , select [ class "ui fluid dropdown", onInput onInputMsg ] playlistOptions
                ]
            ]


viewPlaylistTracks : (PlaylistId -> TrackUri -> a) -> Playlist -> Html a
viewPlaylistTracks onDeleteButtonMsg playlist =
    div []
        [ h2
            [ class "ui section horizontal divider header" ]
            [ i [ class "music icon" ] [], text playlist.name ]
        , p
            []
            [ text
                ("Here are the "
                    ++ (playlist.tracks |> List.length |> toString)
                    ++ " songs you don't listen much in this playlist:"
                )
            ]
        , div
            [ class "ui divided relaxed list" ]
            (List.map (viewTrack onDeleteButtonMsg playlist.id) playlist.tracks)
        ]


viewTrack : (PlaylistId -> TrackUri -> a) -> PlaylistId -> Track -> Html a
viewTrack onDeleteButtonMsg playlistId track =
    div [ class "item" ]
        [ div
            [ class "right floated content" ]
            [ viewDeleteTrackButton onDeleteButtonMsg playlistId track ]
        , div
            [ class "content" ]
            [ p [ class "header" ] [ text track.name ] ]
        ]


viewDeleteTrackButton : (PlaylistId -> TrackUri -> a) -> PlaylistId -> Track -> Html a
viewDeleteTrackButton onDeleteButtonMsg playlistId track =
    if track.isLocal then
        disabledDeleteButton "I can't delete local files from your playlist (yet)"
    else
        deleteButton (onDeleteButtonMsg playlistId track.uri)
