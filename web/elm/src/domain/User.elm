module User exposing (Msg, ExternalMsg(..), User, UserId, update, fetchData, view)

import Error exposing (Error, fetchDataError)
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
    = UserFetched (Result Http.Error User)


type ExternalMsg
    = UserSet
    | FetchFailed Error.Error


update : Msg -> Model -> ( Model, ExternalMsg )
update msg model =
    case msg of
        UserFetched (Ok fetchedUser) ->
            ( fetchedUser, UserSet )

        UserFetched (Err _) ->
            ( model, FetchFailed failedToFetchUserData )


fetchData : Request User -> Cmd Msg
fetchData getCurrentUserProfile =
    Http.send UserFetched getCurrentUserProfile


failedToFetchUserData : Error.Error
failedToFetchUserData =
    fetchDataError "profile"



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
