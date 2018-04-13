module Error exposing (Error, fetchDataError)

import Http exposing (encodeUri)


type alias Error =
    { title : String
    , message : String
    , button : String
    , shouldLoginAgain : Bool
    }


fetchDataError : String -> Error
fetchDataError dataName =
    { title = "I failed to fetch your " ++ dataName ++ "."
    , message = "This often happens when the access token is outdated. Please, <strong>try to log in again</strong>, it could solve the problem.<br><br>If it doesn't, <a href='https://github.com/nicoespeon/my-spotify-groomer/issues/new?title=Failed%20to%20fetch%20user%20" ++ encodeUri dataName ++ "' target='_blank' rel='noopener'>please open an issue</a>."
    , button = "Try to log in again"
    , shouldLoginAgain = True
    }
