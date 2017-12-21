port module MySpotifyGroomer exposing (..)

import Html exposing (Html, program, button, div, span, text, a, img, h1, h2, p, nav, form, label, select, option, i)
import Html.Attributes exposing (src, class, for, id, value, name, disabled, selected, attribute)
import Html.Events exposing (onClick, onInput)
import Http exposing (Error, Request, header, emptyBody, jsonBody, expectJson)
import Navigation exposing (load)
import Json.Decode as Decode exposing (Decoder, at, list, string, int, bool)
import Json.Encode as Encode exposing (object)
import Task exposing (Task)


main : Program Never Model Msg
main =
    program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { accessToken : AccessToken
    , state : State
    , user : User
    , playlists : List Playlist
    , favoriteTracks : List TrackUri
    }


type alias AccessToken =
    String


type alias User =
    { id : UserId
    , name : String
    , profilePictureUrl : Maybe String
    }


type alias UserId =
    String


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


type State
    = Blank
    | Loading
    | Errored String
    | LoadingPlaylists String
    | PlaylistSelection
    | LoadingTracks
    | PlaylistTracks Playlist
    | DeletingTrack


init : ( Model, Cmd Msg )
init =
    ( emptyModel, Cmd.none )


emptyModel : Model
emptyModel =
    { accessToken = ""
    , state = Blank
    , user = User "" "" Nothing
    , playlists = []
    , favoriteTracks = []
    }



-- UPDATE


type Msg
    = LogIn AccessToken
    | UserFetched (Result Error User)
    | FavoriteTracksFetched (Result Error (List TrackUri))
    | PlaylistsFetched (Result Error (List Playlist))
    | SelectPlaylist PlaylistId
    | PlaylistTracksFetched (Result Error Playlist)
    | DeleteTrack PlaylistId TrackUri
    | TrackDeleted (Result Error (List Playlist))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LogIn accessToken ->
            ( { model | state = Loading, accessToken = accessToken }
            , fetchUser accessToken
            )

        UserFetched (Ok user) ->
            ( { model
                | state = LoadingPlaylists "Fetching your favorite tracks…"
                , user = user
              }
            , fetchFavoriteTracks model.accessToken
            )

        UserFetched (Err _) ->
            ( { model | state = Errored "Failed to fetch user data." }
            , load "/login"
            )

        FavoriteTracksFetched (Ok trackUris) ->
            ( { model
                | state = LoadingPlaylists "Fetching your playlists…"
                , favoriteTracks = trackUris
              }
            , fetchPlaylists model.accessToken
            )

        FavoriteTracksFetched (Err _) ->
            ( { model | state = Errored "Failed to fetch user top tracks." }
            , Cmd.none
            )

        PlaylistsFetched (Ok playlists) ->
            ( { model
                | state = PlaylistSelection
                , playlists = ownedByUser model.user.id playlists
              }
            , Cmd.none
            )

        PlaylistsFetched (Err _) ->
            ( { model | state = Errored "Failed to fetch user playlists." }
            , Cmd.none
            )

        SelectPlaylist playlistId ->
            case selectedPlaylist playlistId model.playlists of
                Just playlist ->
                    ( { model | state = LoadingTracks }
                    , fetchPlaylistTracks model.accessToken playlist model.favoriteTracks
                    )

                Nothing ->
                    ( model, Cmd.none )

        PlaylistTracksFetched (Ok playlist) ->
            ( { model | state = PlaylistTracks playlist }, Cmd.none )

        PlaylistTracksFetched (Err _) ->
            ( { model | state = Errored "Failed to fetch playlist tracks." }
            , Cmd.none
            )

        DeleteTrack playlistId trackUri ->
            ( { model | state = DeletingTrack }
            , deleteTrackFromPlaylist model playlistId trackUri
            )

        TrackDeleted (Ok playlists) ->
            ( { model | state = PlaylistSelection, playlists = playlists }
            , Cmd.none
            )

        TrackDeleted (Err _) ->
            ( { model | state = Errored "Failed to delete track." }
            , Cmd.none
            )


ownedByUser : UserId -> List Playlist -> List Playlist
ownedByUser userId =
    List.filter (\p -> p.ownerId == userId)


selectedPlaylist : PlaylistId -> List Playlist -> Maybe Playlist
selectedPlaylist playlistId =
    List.filter (\p -> p.id == playlistId)
        >> List.head


getFromSpotify : AccessToken -> String -> Decoder a -> Request a
getFromSpotify accessToken url decoder =
    let
        authorizationHeader =
            header "Authorization" ("Bearer " ++ accessToken)
    in
        Http.request
            { method = "GET"
            , headers = [ authorizationHeader ]
            , url = url
            , body = emptyBody
            , expect = expectJson decoder
            , timeout = Nothing
            , withCredentials = False
            }


fetchUser : AccessToken -> Cmd Msg
fetchUser accessToken =
    let
        url =
            "https://api.spotify.com/v1/me"
    in
        Http.send UserFetched (getFromSpotify accessToken url userDecoder)


fetchFavoriteTracks : AccessToken -> Cmd Msg
fetchFavoriteTracks accessToken =
    let
        url =
            "https://api.spotify.com/v1/me/top/tracks?time_range=short_term&limit=100"
    in
        Http.send FavoriteTracksFetched (getFromSpotify accessToken url trackUrisDecoder)


fetchPlaylists : AccessToken -> Cmd Msg
fetchPlaylists accessToken =
    let
        url =
            "https://api.spotify.com/v1/me/playlists?fields=items(id,owner.id,name,tracks.href)&limit=50"
    in
        Http.send PlaylistsFetched (getFromSpotify accessToken url playlistsDecoder)


fetchPlaylistTracks : AccessToken -> Playlist -> List TrackUri -> Cmd Msg
fetchPlaylistTracks accessToken playlist favoriteTracks =
    let
        url =
            playlist.tracksUrl ++ "?fields=items(track.name,track.uri,is_local),next"
    in
        fetchPlaylistTracksWithUrl accessToken playlist favoriteTracks url
            |> Task.attempt PlaylistTracksFetched


fetchPlaylistTracksWithUrl : AccessToken -> Playlist -> List TrackUri -> String -> Task Error Playlist
fetchPlaylistTracksWithUrl accessToken playlist favoriteTracks url =
    let
        addFavoriteTracksToPlaylist =
            addTracksToPlaylist playlist favoriteTracks
    in
        getFromSpotify accessToken url paginatedTracksDecoder
            |> Http.toTask
            |> Task.andThen
                (\paginatedTracks ->
                    case paginatedTracks.next of
                        Just nextUrl ->
                            addFavoriteTracksToPlaylist paginatedTracks.tracks
                                |> Task.andThen
                                    (\newPlaylist -> fetchPlaylistTracksWithUrl accessToken newPlaylist favoriteTracks nextUrl)

                        Nothing ->
                            addFavoriteTracksToPlaylist paginatedTracks.tracks
                )


addTracksToPlaylist : Playlist -> List TrackUri -> List Track -> Task Error Playlist
addTracksToPlaylist playlist favoriteTracks tracks =
    let
        newTracks =
            playlist.tracks
                |> List.append tracks
                |> List.filter (\track -> not (List.member track.uri favoriteTracks))
    in
        Task.succeed { playlist | tracks = newTracks }


deleteTrackFromPlaylist : Model -> PlaylistId -> TrackUri -> Cmd Msg
deleteTrackFromPlaylist model playlistId trackUri =
    let
        updatedPlaylists =
            playlistsWithoutTrack trackUri model.playlists

        authorizationHeader =
            header "Authorization" ("Bearer " ++ model.accessToken)

        url =
            "https://api.spotify.com/v1/users/" ++ model.user.id ++ "/playlists/" ++ playlistId ++ "/tracks"

        body =
            object
                [ ( "tracks"
                  , Encode.list
                        [ object
                            [ ( "uri", Encode.string trackUri ) ]
                        ]
                  )
                ]

        deleteRequest =
            Http.request
                { method = "DELETE"
                , headers = [ authorizationHeader ]
                , url = url
                , body = jsonBody body
                , expect = expectJson (Decode.succeed updatedPlaylists)
                , timeout = Nothing
                , withCredentials = False
                }
    in
        Http.send TrackDeleted (deleteRequest)


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



-- DECODERS


userDecoder : Decoder User
userDecoder =
    Decode.map3 User
        (at [ "id" ] string)
        (at [ "display_name" ] string)
        (Decode.map
            List.head
            (at [ "images" ] (list (at [ "url" ] string)))
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


trackUrisDecoder : Decoder (List TrackUri)
trackUrisDecoder =
    at [ "items" ]
        (Decode.list (at [ "uri" ] string))


tracksDecoder : Decoder (List Track)
tracksDecoder =
    at [ "items" ]
        (Decode.list
            (Decode.map3 Track
                (at [ "track", "uri" ] string)
                (at [ "track", "name" ] string)
                (at [ "is_local" ] bool)
            )
        )


paginatedTracksDecoder : Decoder PaginatedTracks
paginatedTracksDecoder =
    Decode.map2 PaginatedTracks
        tracksDecoder
        (Decode.maybe (at [ "next" ] string))



-- VIEW


view : Model -> Html Msg
view model =
    case model.state of
        Blank ->
            text ""

        Loading ->
            loader "Fetching data from Spotify…"

        LoadingPlaylists message ->
            div []
                [ mainNav model.user
                , mainContainer [ pageTitle, loaderBlock message ]
                ]

        PlaylistSelection ->
            div []
                [ mainNav model.user
                , mainContainer [ pageTitle, playlistSelectForm model.playlists ]
                ]

        LoadingTracks ->
            div []
                [ mainNav model.user
                , mainContainer
                    [ pageTitle
                    , playlistSelectForm model.playlists
                    , loaderBlock "Fetching playlist tracks…"
                    ]
                ]

        PlaylistTracks playlist ->
            div []
                [ mainNav model.user
                , mainContainer
                    [ pageTitle
                    , playlistSelectForm model.playlists
                    , renderPlaylistTracks playlist
                    ]
                ]

        DeletingTrack ->
            div []
                [ mainNav model.user
                , mainContainer [ pageTitle, loaderBlock "Deleting the track…" ]
                ]

        Errored message ->
            text ("An error occurred: " ++ message)


mainContainer : List (Html Msg) -> Html Msg
mainContainer children =
    div [ class "ui main text container" ] children


pageTitle : Html Msg
pageTitle =
    h1 [] [ text "Groom your Spotify playlists" ]


loader : String -> Html Msg
loader message =
    div [ class "ui active inverted dimmer" ]
        [ div
            [ class "ui text loader" ]
            [ text message ]
        ]


loaderBlock : String -> Html Msg
loaderBlock message =
    div
        [ class "ui segment" ]
        [ loader message
        , img
            [ class "ui wireframe image"
            , src "/images/wireframe/short-paragraph.png"
            ]
            []
        ]


mainNav : User -> Html Msg
mainNav user =
    nav
        [ class "ui fixed borderless secondary pointing nav menu" ]
        [ div
            [ class "ui container" ]
            [ div
                [ class "header item" ]
                [ renderUser user ]
            ]
        ]


renderUser : User -> Html Msg
renderUser user =
    case user.profilePictureUrl of
        Just profilePictureUrl ->
            div []
                [ img [ class "ui avatar image", src profilePictureUrl ] []
                , span [] [ text ("Hello " ++ user.name) ]
                ]

        Nothing ->
            text ("Hello " ++ user.name)


playlistSelectForm : List Playlist -> Html Msg
playlistSelectForm playlists =
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


renderPlaylistTracks : Playlist -> Html Msg
renderPlaylistTracks playlist =
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
            (List.map (renderTrack playlist.id) playlist.tracks)
        ]


renderTrack : PlaylistId -> Track -> Html Msg
renderTrack playlistId track =
    div [ class "item" ]
        [ div
            [ class "right floated content" ]
            [ deleteTrackButton playlistId track ]
        , div
            [ class "content" ]
            [ p [ class "header" ] [ text track.name ] ]
        ]


deleteTrackButton : PlaylistId -> Track -> Html Msg
deleteTrackButton playlistId track =
    if track.isLocal then
        disabledDeleteButton "I can't delete local files from your playlist (yet)"
    else
        deleteButton (DeleteTrack playlistId track.uri)


deleteButton : Msg -> Html Msg
deleteButton onClickAction =
    button
        [ class "ui icon red button", onClick onClickAction ]
        [ i [ class "trash outline icon" ] [] ]


disabledDeleteButton : String -> Html Msg
disabledDeleteButton reason =
    div
        [ attribute "data-tooltip" reason, attribute "data-inverted" "" ]
        [ button
            [ class "ui icon disabled red button" ]
            [ i [ class "trash outline icon" ] [] ]
        ]



-- SUBSCRIPTIONS


port accessToken : (String -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    accessToken LogIn
