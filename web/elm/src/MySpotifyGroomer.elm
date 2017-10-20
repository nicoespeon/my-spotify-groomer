port module MySpotifyGroomer exposing (..)

import Html exposing (Html, program, button, div, text, a, img)
import Html.Attributes exposing (src)
import Http exposing (header, emptyBody, expectJson)
import Navigation exposing (load)
import Json.Decode as Decode exposing (at, string, list)


main : Program Never Model Msg
main =
    program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { fetchUserStatus : FetchUserStatuses
    , user : User
    }


type alias User =
    { name : String
    , profilePictureUrl : Maybe String
    }


type FetchUserStatuses
    = NotStarted
    | Fetching
    | Error
    | Success



-- INIT


init : ( Model, Cmd Msg )
init =
    ( emptyModel, Cmd.none )


emptyModel : Model
emptyModel =
    { fetchUserStatus = NotStarted
    , user = User "" Nothing
    }



-- UPDATE


type Msg
    = LogIn AccessToken
    | FetchUser (Result Http.Error User)


type alias AccessToken =
    String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchUser (Ok user) ->
            ( { model | fetchUserStatus = Success, user = user }, Cmd.none )

        FetchUser (Err _) ->
            ( { model | fetchUserStatus = Error }, load "/login" )

        LogIn accessToken ->
            ( { model | fetchUserStatus = Fetching }, fetchUser accessToken )


fetchUser : AccessToken -> Cmd Msg
fetchUser accessToken =
    let
        authorizationHeader =
            header "Authorization" ("Bearer " ++ accessToken)

        request =
            Http.request
                { method = "GET"
                , headers = [ authorizationHeader ]
                , url = "https://api.spotify.com/v1/me"
                , body = emptyBody
                , expect = expectJson userDecoder
                , timeout = Nothing
                , withCredentials = False
                }
    in
        Http.send FetchUser request


userDecoder : Decode.Decoder User
userDecoder =
    Decode.map2 User
        (at [ "display_name" ] string)
        (Decode.map
            List.head
            (at [ "images" ] (list (at [ "url" ] string)))
        )



-- VIEW


view : Model -> Html Msg
view model =
    case model.fetchUserStatus of
        NotStarted ->
            text "Fetch of user data has not started yet."

        Fetching ->
            text "Fetching user data from Spotify…"

        Error ->
            text "Something went wrong when user data were fetched!"

        Success ->
            renderUser model.user


renderUser : User -> Html Msg
renderUser user =
    case user.profilePictureUrl of
        Just profilePictureUrl ->
            div []
                [ img [ src profilePictureUrl ] []
                , text ("Hello " ++ user.name)
                ]

        Nothing ->
            text ("Hello " ++ user.name)



-- SUBSCRIPTIONS


port accessToken : (String -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    accessToken LogIn
