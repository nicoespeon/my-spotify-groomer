module User exposing (User, UserId, fetchData, view)

import Html exposing (Html, div, text, img, span)
import Html.Attributes exposing (class, src)
import Json.Decode as Decode exposing (Decoder, at, list, map, map3, string)


type alias User =
    { id : UserId
    , name : String
    , profilePictureUrl : Maybe String
    }


type alias UserId =
    String


decoder : Decoder User
decoder =
    map3 User
        (at [ "id" ] string)
        (at [ "display_name" ] string)
        (map
            List.head
            (at [ "images" ] (list (at [ "url" ] string)))
        )


fetchData : (String -> Decoder User -> Cmd a) -> Cmd a
fetchData fetch =
    fetch "/me" decoder


view : User -> Html a
view user =
    case user.profilePictureUrl of
        Just profilePictureUrl ->
            div []
                [ img [ class "ui avatar image", src profilePictureUrl ] []
                , span [] [ text ("Hello " ++ user.name) ]
                ]

        Nothing ->
            text ("Hello " ++ user.name)
