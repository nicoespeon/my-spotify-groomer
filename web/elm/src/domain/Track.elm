module Track
    exposing
        ( Track
        , TrackUri
        , PaginatedTracks
        , fetchFavoriteTracks
        , fetchTracks
        , setDeletion
        , toggleDeletion
        , toBeDeleted
        , localsToBeDeleted
        , notLocalsToBeDeleted
        , view
        )

import Date exposing (Date)
import Html exposing (Html, div, text, label, input)
import Html.Attributes exposing (id, class, type_, name, checked, for)
import Html.Events exposing (onClick)
import Http exposing (Error, Request)
import Spotify exposing (Url, Offset, Limit)
import Task exposing (Task)
import Time exposing (Time)


-- MODEL


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



-- UPDATE


fetchFavoriteTracks :
    (Offset -> Limit -> Request (List TrackUri))
    -> (Result Error (List TrackUri) -> a)
    -> Cmd a
fetchFavoriteTracks getCurrentUserTopTracks msg =
    let
        -- Spotify limits number of top tracks that can be fetched to 50.
        -- But we can hack a bit and retrieve up to 99 using 49 as the offset.
        -- Offset of 50+ returns no track.
        -- short_term = last 4 weeks (recent listenings)
        fetchShortTermFirst50TopTracks =
            getCurrentUserTopTracks 0 50

        fetchShortTerm49To99TopTracks =
            getCurrentUserTopTracks 49 50
    in
        Task.attempt
            msg
            (getTrackUris fetchShortTermFirst50TopTracks []
                |> Task.andThen (getTrackUris fetchShortTerm49To99TopTracks)
            )


getTrackUris : Request (List TrackUri) -> List TrackUri -> Task Error (List TrackUri)
getTrackUris fetchTrackUris trackUris =
    Http.toTask fetchTrackUris
        |> Task.andThen (Task.succeed << List.append trackUris)


fetchTracks :
    (Result Error a -> b)
    -> Time
    -> List TrackUri
    -> (List Track -> Task Error a)
    -> (Url -> Request PaginatedTracks)
    -> String
    -> Cmd b
fetchTracks msg referenceTime favoriteTrackUris onTracksFetched getPlaylistTracks url =
    Task.attempt
        msg
        (fetchTracksWithUrl getPlaylistTracks url []
            |> Task.andThen
                (onTracksFetched
                    << List.filter
                        (isNotListenedAnymore referenceTime favoriteTrackUris)
                )
        )


fetchTracksWithUrl :
    (Url -> Request PaginatedTracks)
    -> String
    -> List Track
    -> Task Error (List Track)
fetchTracksWithUrl getPlaylistTracks url tracks =
    Http.toTask (getPlaylistTracks url)
        |> Task.andThen
            (\paginatedTracks ->
                let
                    newTracks =
                        List.append tracks paginatedTracks.tracks
                in
                    case paginatedTracks.next of
                        Just nextUrl ->
                            fetchTracksWithUrl getPlaylistTracks nextUrl newTracks

                        Nothing ->
                            Task.succeed (addPositionToTracks newTracks)
            )


addPositionToTracks : List Track -> List Track
addPositionToTracks =
    List.indexedMap (\i track -> { track | position = i })


setDeletion : Bool -> Track -> Track
setDeletion shouldBeDeleted track =
    { track | shouldBeDeleted = shouldBeDeleted }


toggleDeletion : Track -> Track
toggleDeletion track =
    { track | shouldBeDeleted = not track.shouldBeDeleted }


toBeDeleted : List Track -> List Track
toBeDeleted =
    List.filter .shouldBeDeleted


localsToBeDeleted : List Track -> List Track
localsToBeDeleted =
    List.filter .isLocal
        << toBeDeleted


notLocalsToBeDeleted : List Track -> List Track
notLocalsToBeDeleted =
    List.filter (not << .isLocal)
        << toBeDeleted


isNotListenedAnymore : Time -> List TrackUri -> Track -> Bool
isNotListenedAnymore referenceTime favoriteTrackUris track =
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



-- VIEW


view : Track -> a -> Html a
view track onClick_ =
    div [ class "item" ]
        [ div
            [ class "ui checkbox" ]
            [ input
                [ type_ "checkbox"
                , name track.uri
                , id track.uri
                , checked track.shouldBeDeleted
                , onClick onClick_
                ]
                []
            , label [ for track.uri ] [ text track.name ]
            ]
        ]
