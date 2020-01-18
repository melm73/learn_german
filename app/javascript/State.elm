module State exposing (..)


type alias AppState =
    { user : User
    , urls : Urls
    , words : List Word
    }


type alias User =
    { name : String }


type alias Urls =
    { csrfToken : String
    , logoutUrl : String
    , progressUrl : String
    , currentUserProfileUrl : String
    , wordsUrl : String
    }


type alias Word =
    { id : String
    , german : String
    , article : Maybe Article
    , category : String
    , plural : Maybe String
    , level : Maybe Int
    }


type Article
    = Der
    | Die
    | Das
