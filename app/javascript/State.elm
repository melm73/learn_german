module State exposing (..)


type alias AppState =
    { user : User
    , urls : Urls
    }


type alias User =
    { name : String }


type alias Urls =
    { csrfToken : String
    , profileUrl : String
    , logoutUrl : String
    , progressUrl : String
    , currentUserProfileUrl : String
    }
