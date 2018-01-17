module SemanticUI
    exposing
        ( deleteButton
        , disabledDeleteButton
        , loader
        , loaderBlock
        )

import Html exposing (Html, div, text, img, button, i)
import Html.Attributes exposing (class, src, attribute)
import Html.Events exposing (onClick)


deleteButton : a -> Html a
deleteButton onClickMsg =
    button
        [ class "ui icon red button", onClick onClickMsg ]
        [ i [ class "trash outline icon" ] [] ]


disabledDeleteButton : String -> Html a
disabledDeleteButton reason =
    div
        [ attribute "data-tooltip" reason, attribute "data-inverted" "" ]
        [ button
            [ class "ui icon disabled red button" ]
            [ i [ class "trash outline icon" ] [] ]
        ]


loader : String -> Html a
loader message =
    div [ class "ui active inverted dimmer" ]
        [ div
            [ class "ui text loader" ]
            [ text message ]
        ]


loaderBlock : String -> Html a
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
