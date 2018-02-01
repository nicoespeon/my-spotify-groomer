module Track
    exposing
        ( Track
        , TrackUri
        , PaginatedTracks
        , fetchFavoriteTracks
        , fetchTracks
        , toggleDeletion
        , toBeDeleted
        , isNotListenedAnymore
        , localDeleteBody
        , notLocalDeleteBody
        , view
        )

import Date exposing (Date)
import Html exposing (Html, div, text, label, input)
import Html.Attributes exposing (id, class, type_, name, checked, for)
import Html.Events exposing (onClick)
import Http exposing (Error, Request)
import Json.Decode as Decode exposing (Decoder, at, string, bool)
import Json.Encode as Encode
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
    (String -> Decoder (List TrackUri) -> Request (List TrackUri))
    -> (Result Error (List TrackUri) -> a)
    -> Cmd a
fetchFavoriteTracks fetch msg =
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
            msg
            (getTrackUris fetchShortTermFirst50TopTracks []
                |> Task.andThen (getTrackUris fetchShortTerm49To99TopTracks)
            )


trackUrisDecoder : Decoder (List TrackUri)
trackUrisDecoder =
    at [ "items" ]
        (Decode.list (at [ "uri" ] string))


getTrackUris : Request (List TrackUri) -> List TrackUri -> Task Error (List TrackUri)
getTrackUris fetchTrackUris trackUris =
    Http.toTask fetchTrackUris
        |> Task.andThen (Task.succeed << List.append trackUris)


fetchTracks :
    (String -> Decoder PaginatedTracks -> Request PaginatedTracks)
    -> (Result Error a -> b)
    -> (List Track -> Task Error a)
    -> String
    -> Cmd b
fetchTracks fetch msg onTracksFetched url =
    Task.attempt
        msg
        (fetchTracksWithUrl fetch onTracksFetched url [])


fetchTracksWithUrl :
    (String -> Decoder PaginatedTracks -> Request PaginatedTracks)
    -> (List Track -> Task Error a)
    -> String
    -> List Track
    -> Task Error a
fetchTracksWithUrl fetch onTracksFetched url tracks =
    Http.toTask (fetch url paginatedTracksDecoder)
        |> Task.andThen
            (\paginatedTracks ->
                let
                    newTracks =
                        List.append tracks paginatedTracks.tracks
                in
                    case paginatedTracks.next of
                        Just nextUrl ->
                            fetchTracksWithUrl fetch onTracksFetched nextUrl newTracks

                        Nothing ->
                            onTracksFetched (addPositionToTracks newTracks)
            )


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


addPositionToTracks : List Track -> List Track
addPositionToTracks =
    List.indexedMap (\i track -> { track | position = i })


toggleDeletion : Track -> Track
toggleDeletion track =
    { track | shouldBeDeleted = not track.shouldBeDeleted }


toBeDeleted : List Track -> List Track
toBeDeleted =
    List.filter .shouldBeDeleted


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


localDeleteBody : String -> List Track -> Encode.Value
localDeleteBody snapshotId tracks =
    if List.length tracks > 0 then
        Encode.object
            [ ( "positions"
              , tracks
                    |> List.filter .isLocal
                    |> toBeDeleted
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
                |> List.filter (not << .isLocal)
                |> toBeDeleted
                |> List.map
                    (\track ->
                        Encode.object
                            [ ( "uri", Encode.string track.uri ) ]
                    )
                |> Encode.list
          )
        ]



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
