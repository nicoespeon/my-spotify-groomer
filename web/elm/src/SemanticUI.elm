module SemanticUI
    exposing
        ( confirm
        , deleteButton
        , disabledDeleteButton
        , loader
        , loaderBlock
        )

import Html exposing (Html, div, text, img, button, i)
import Html.Attributes exposing (class, src, attribute)
import Html.Events exposing (onClick)


confirm : a -> a -> Html a -> String -> String -> Html a
confirm onConfirmMsg onCancelMsg message confirmText cancelText =
    div []
        [ message
        , button
            [ class "ui icon red button", onClick onConfirmMsg ]
            [ text confirmText ]
        , button
            [ class "ui icon basic button", onClick onCancelMsg ]
            [ text cancelText ]
        ]


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
loader loaderText =
    div [ class "ui active inverted dimmer" ]
        [ div
            [ class "ui text loader" ]
            [ text loaderText ]
        ]


loaderBlock : String -> Html a
loaderBlock loaderText =
    div
        [ class "ui segment" ]
        [ loader loaderText
        , img
            [ class "ui wireframe image"
            , src "/images/wireframe/short-paragraph.png"
            ]
            []
        ]
