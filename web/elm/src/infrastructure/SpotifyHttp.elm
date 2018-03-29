module SpotifyHttp exposing (AccessToken, spotifyHttp)

import Date exposing (Date)
import Http exposing (Header, Request, Error, header, emptyBody, jsonBody, expectJson)
import IControlSpotify exposing (IControlSpotify)
import Json.Decode as Decode exposing (Decoder, at, bool, list, string)
import Json.Encode as Encode
import Playlist exposing (PlaylistId)
import Spotify exposing (Url, Offset, Limit, IsLocal, toSpotifyUrl)
import Playlist exposing (Playlist, SnapshotId)
import Track exposing (Track, TrackUri, PaginatedTracks)
import User exposing (User, UserId)


type alias AccessToken =
    String


spotifyHttp : AccessToken -> IControlSpotify
spotifyHttp accessToken =
    { getCurrentUserProfile = getCurrentUserProfile accessToken
    , getCurrentUserTopTracks = getCurrentUserTopTracks accessToken
    , getCurrentUserPlaylists = getCurrentUserPlaylists accessToken
    , getPlaylistTracks = getPlaylistTracks accessToken
    , removeTracksFromPlaylist = removeTracksFromPlaylist accessToken
    }


spotifyBaseUrl : Url
spotifyBaseUrl =
    "https://api.spotify.com/v1"


authorizationHeader : AccessToken -> Header
authorizationHeader accessToken =
    header "Authorization" ("Bearer " ++ accessToken)


getCurrentUserProfile : AccessToken -> Request User
getCurrentUserProfile accessToken =
    get "/me" accessToken decodeUser


decodeUser : Decoder User
decodeUser =
    Decode.map3 User
        (at [ "id" ] string)
        (at [ "display_name" ] string)
        (Decode.map
            List.head
            (at [ "images" ] (list (at [ "url" ] string)))
        )


getCurrentUserTopTracks : AccessToken -> Offset -> Limit -> Request (List TrackUri)
getCurrentUserTopTracks accessToken offset limit =
    get
        ("/me/top/tracks?time_range=short_term&offset="
            ++ (toString offset)
            ++ "&limit="
            ++ (toString limit)
        )
        accessToken
        trackUrisDecoder


trackUrisDecoder : Decoder (List TrackUri)
trackUrisDecoder =
    at [ "items" ]
        (Decode.list (at [ "uri" ] string))


getCurrentUserPlaylists : AccessToken -> Request (List Playlist)
getCurrentUserPlaylists accessToken =
    get
        "/me/playlists?fields=items(id,owner.id,name,tracks.href,snapshot_id)&limit=50"
        accessToken
        playlistsDecoder


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


getPlaylistTracks : AccessToken -> Url -> Request PaginatedTracks
getPlaylistTracks accessToken trackUrl =
    get
        (trackUrl ++ "?fields=items(track.name,track.uri,is_local,added_at),next")
        accessToken
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


get : Url -> AccessToken -> Decoder a -> Request a
get url accessToken decoder =
    Http.request
        { method = "GET"
        , headers = [ authorizationHeader accessToken ]
        , url = toSpotifyUrl spotifyBaseUrl url
        , body = emptyBody
        , expect = expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }


removeTracksFromPlaylist : AccessToken -> UserId -> PlaylistId -> SnapshotId -> List Track -> IsLocal -> Request SnapshotId
removeTracksFromPlaylist accessToken userId playlistId snapshotId tracks isLocal =
    let
        body =
            if isLocal then
                localDeleteBody snapshotId
            else
                notLocalDeleteBody
    in
        delete
            ("/users/" ++ userId ++ "/playlists/" ++ playlistId ++ "/tracks")
            accessToken
            snapshotIdDecoder
            (body tracks)


localDeleteBody : SnapshotId -> List Track -> Encode.Value
localDeleteBody snapshotId tracks =
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


notLocalDeleteBody : List Track -> Encode.Value
notLocalDeleteBody tracks =
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


delete : Url -> AccessToken -> Decoder a -> Encode.Value -> Request a
delete url accessToken decoder body =
    Http.request
        { method = "DELETE"
        , headers = [ authorizationHeader accessToken ]
        , url = toSpotifyUrl spotifyBaseUrl url
        , body = jsonBody body
        , expect = expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }
