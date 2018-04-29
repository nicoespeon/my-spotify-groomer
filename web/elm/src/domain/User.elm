module User exposing (Msg, ExternalMsg(..), User, UserId, update, fetchData, view)

import Error exposing (Error, fetchDataError)
import Html exposing (Html, div, span, text, p, b)
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
            div [ class "islet text-center" ]
                [ p []
                    [ text "🎩 Hello "
                    , span [ class "title-font" ] [ text user.name ]
                    , text ". Find tracks you added "
                    , b [] [ text "more that 14 days ago" ]
                    , text " which are "
                    , b [] [ text " not in your top tracks" ]
                    , text ". Delete them with a snap!"
                    ]
                ]

        -- not in top tracks, added more than 14 days ago
        Nothing ->
            text ("Hello " ++ user.name)
