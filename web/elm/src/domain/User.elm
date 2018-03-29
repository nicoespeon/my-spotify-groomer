module User exposing (Msg, ExternalMsg(..), User, UserId, update, fetchData, view)

import Html exposing (Html, div, text, img, span)
import Html.Attributes exposing (class, src)
import Http exposing (Request, Error)


-- MODEL


type alias Model =
    User


type alias User =
    { id : UserId
    , name : String
    , profilePictureUrl : Maybe String
    }


type alias UserId =
    String



-- UPDATE


type Msg
    = UserFetched (Result Error User)


type ExternalMsg
    = UserSet
    | FetchFailed


update : Msg -> Model -> ( Model, ExternalMsg )
update msg model =
    case msg of
        UserFetched (Ok fetchedUser) ->
            ( fetchedUser, UserSet )

        UserFetched (Err _) ->
            ( model, FetchFailed )


fetchData : Request User -> Cmd Msg
fetchData getCurrentUserProfile =
    Http.send UserFetched getCurrentUserProfile



-- VIEW


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
