port module MySpotifyGroomer exposing (main)

import Html exposing (Html, program, h1, div, text, nav)
import Html.Attributes exposing (class)
import Navigation exposing (load)
import SemanticUI exposing (confirm, loader, loaderBlock)
import Spotify exposing (AccessToken, get, delete)
import Task exposing (Task)
import Time exposing (Time)
import Track exposing (Track)
import User exposing (User, UserId)


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
    , track : Track.Model
    , referenceTime : Time
    }


type State
    = Blank
    | Loading
    | Loaded
    | Errored String


init : ( Model, Cmd Msg )
init =
    ( emptyModel, setReferenceTimeToNow )


emptyModel : Model
emptyModel =
    { accessToken = ""
    , state = Blank
    , user = User "" "" Nothing
    , track = Track.emptyModel
    , referenceTime = 0
    }



-- UPDATE


type Msg
    = ReferenceTimeSet Time
    | LogIn AccessToken
    | UserMsg User.Msg
    | TrackMsg Track.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReferenceTimeSet time ->
            ( { model | referenceTime = time }, Cmd.none )

        LogIn accessToken ->
            ( { model | state = Loading, accessToken = accessToken }
            , fetchUser accessToken
            )

        UserMsg userMsg ->
            let
                ( newUser, msgFromUser ) =
                    User.update userMsg model.user

                ( newState, newCmd ) =
                    case msgFromUser of
                        User.UserSet ->
                            ( Loaded
                            , fetchFavoriteTracks model.accessToken
                            )

                        User.FetchFailed ->
                            ( Errored "Failed to fetch user data."
                            , load "/login"
                            )
            in
                ( { model | state = newState, user = newUser }, newCmd )

        TrackMsg trackMsg ->
            let
                ( newTrack, newTrackMsg ) =
                    Track.update
                        (Spotify.get model.accessToken)
                        (Spotify.get model.accessToken)
                        (Spotify.delete model.accessToken)
                        model.referenceTime
                        model.user.id
                        trackMsg
                        model.track
            in
                ( { model | state = Loaded, track = newTrack }
                , Cmd.map TrackMsg newTrackMsg
                )


setReferenceTimeToNow : Cmd Msg
setReferenceTimeToNow =
    Task.perform ReferenceTimeSet Time.now


fetchUser : AccessToken -> Cmd Msg
fetchUser accessToken =
    User.fetchData (Spotify.get accessToken)
        |> Cmd.map UserMsg


fetchFavoriteTracks : AccessToken -> Cmd Msg
fetchFavoriteTracks accessToken =
    Track.fetchFavoriteTracks (Spotify.get accessToken)
        |> Cmd.map TrackMsg



-- VIEW


view : Model -> Html Msg
view model =
    case model.state of
        Blank ->
            text ""

        Loading ->
            loader "Fetching data from Spotify…"

        Loaded ->
            div []
                [ mainNav model.user
                , mainContainer
                    [ pageTitle
                    , Track.view model.track |> Html.map TrackMsg
                    ]
                ]

        Errored message ->
            text ("An error occurred: " ++ message)


mainContainer : List (Html Msg) -> Html Msg
mainContainer =
    div [ class "ui main text container" ]


pageTitle : Html Msg
pageTitle =
    h1 [] [ text "Groom your Spotify playlists" ]


mainNav : User -> Html Msg
mainNav user =
    nav
        [ class "ui fixed borderless secondary pointing nav menu" ]
        [ div
            [ class "ui container" ]
            [ div
                [ class "header item" ]
                [ User.view user ]
            ]
        ]



-- SUBSCRIPTIONS


port accessToken : (String -> a) -> Sub a


subscriptions : Model -> Sub Msg
subscriptions model =
    accessToken LogIn
