module State exposing (..)


type alias State =
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
    }
