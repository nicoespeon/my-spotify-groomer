module MySpotifyGroomer exposing (..)

import Html exposing (Html, program, button, div, text, a)


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
    ( "", Cmd.none )



-- UPDATE


type Msg
    = Nothing


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Nothing ->
            ( "", Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ text "You're connected!" ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
