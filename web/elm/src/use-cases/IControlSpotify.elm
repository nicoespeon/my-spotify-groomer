module IControlSpotify exposing (IControlSpotify)

import Http exposing (Request)
import Spotify exposing (Offset, Limit, Url, IsLocal)
import Playlist exposing (Playlist, PlaylistId, SnapshotId)
import Track exposing (Track, TrackUri, PaginatedTracks)
import User exposing (User, UserId)


type alias IControlSpotify =
    { getCurrentUserProfile : Request User
    , getCurrentUserTopTracks : Offset -> Limit -> Request (List TrackUri)
    , getCurrentUserPlaylists : Request (List Playlist)
    , getPlaylistTracks : Url -> Request PaginatedTracks
    , removeTracksFromPlaylist : UserId -> PlaylistId -> SnapshotId -> List Track -> IsLocal -> Request SnapshotId
    }
