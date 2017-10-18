port module MySpotifyGroomer exposing (..)

import Html exposing (Html, program, button, div, text, a)
import Http exposing (header, emptyBody, expectStringResponse)
import Navigation exposing (load)


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
    String



-- INIT


init : ( Model, Cmd Msg )
init =
    ( "Not yet", Cmd.none )



-- UPDATE


type alias AccessToken =
    String


type Msg
    = FetchData (Result Http.Error String)
    | LoggedIn AccessToken


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchData (Ok model) ->
            ( model, Cmd.none )

        FetchData (Err _) ->
            ( "Failed to fetch data", load "/login" )

        LoggedIn accessToken ->
            ( "Fetching the accessToken…", fetchData accessToken )


fetchData : AccessToken -> Cmd Msg
fetchData accessToken =
    let
        authorizationHeader =
            header "Authorization" ("Bearer " ++ accessToken)

        request =
            Http.request
                { method = "GET"
                , headers = [ authorizationHeader ]
                , url = "https://api.spotify.com/v1/me"
                , body = emptyBody
                , expect = expectStringResponse (\_ -> Ok "Yes!")
                , timeout = Nothing
                , withCredentials = False
                }
    in
        Http.send FetchData request



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ text ("You're connected? " ++ model) ]



-- SUBSCRIPTIONS


port accessToken : (String -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    accessToken LoggedIn
