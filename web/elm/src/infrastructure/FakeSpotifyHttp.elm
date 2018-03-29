module FakeSpotifyHttp exposing (fakeSpotifyHttp)

import Date exposing (Date)
import Http exposing (Request, emptyBody, expectJson)
import IControlSpotify exposing (IControlSpotify)
import Json.Decode as Decode exposing (Decoder, at, bool, string)
import Playlist exposing (PlaylistId)
import Spotify exposing (Url, Offset, Limit, IsLocal, toSpotifyUrl)
import Playlist exposing (Playlist, SnapshotId)
import Track exposing (Track, TrackUri, PaginatedTracks)
import User exposing (User, UserId)


fakeSpotifyHttp : IControlSpotify
fakeSpotifyHttp =
    { getCurrentUserProfile = getCurrentUserProfile
    , getCurrentUserTopTracks = getCurrentUserTopTracks
    , getCurrentUserPlaylists = getCurrentUserPlaylists
    , getPlaylistTracks = getPlaylistTracks
    , removeTracksFromPlaylist = removeTracksFromPlaylist
    }


spotifyBaseUrl : Url
spotifyBaseUrl =
    "http://localhost:4000/fake-spotify-api"


getCurrentUserProfile : Request User
getCurrentUserProfile =
    get "/me" decodeUser


decodeUser : Decoder User
decodeUser =
    Decode.map3 User
        (at [ "id" ] string)
        (at [ "display_name" ] string)
        (Decode.map
            List.head
            (at [ "images" ] (Decode.list (at [ "url" ] string)))
        )


getCurrentUserTopTracks : Offset -> Limit -> Request (List TrackUri)
getCurrentUserTopTracks _ _ =
    get "/me/top/tracks" trackUrisDecoder


trackUrisDecoder : Decoder (List TrackUri)
trackUrisDecoder =
    at [ "items" ]
        (Decode.list (at [ "uri" ] string))


getCurrentUserPlaylists : Request (List Playlist)
getCurrentUserPlaylists =
    get "/me/playlists" playlistsDecoder


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


getPlaylistTracks : Url -> Request PaginatedTracks
getPlaylistTracks _ =
    get
        "/users/nicoespeon/playlists/7tlxsXWYH6BqzvsVSfWE98/tracks"
        paginatedTracksDecoder


paginatedTracksDecoder : Decoder PaginatedTracks
paginatedTracksDecoder =
    Decode.map2 PaginatedTracks
        tracksDecoder
        (Decode.maybe (at [ "next" ] string))


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


get : Url -> Decoder a -> Request a
get url decoder =
    Http.request
        { method = "GET"
        , headers = []
        , url = toSpotifyUrl spotifyBaseUrl url
        , body = emptyBody
        , expect = expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }


removeTracksFromPlaylist : UserId -> PlaylistId -> SnapshotId -> List Track -> IsLocal -> Request SnapshotId
removeTracksFromPlaylist _ _ _ _ _ =
    delete
        "/users/nicoespeon/playlists/7tlxsXWYH6BqzvsVSfWE98/tracks"
        snapshotIdDecoder


delete : Url -> Decoder a -> Request a
delete url decoder =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = toSpotifyUrl spotifyBaseUrl url
        , body = emptyBody
        , expect = expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }
