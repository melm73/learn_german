module State exposing (..)


type alias AppState =
    { user : User
    , urls : Urls
    , words : List Word
    , filter : Filter
    }


type alias User =
    { name : String }


type alias Urls =
    { csrfToken : String
    , logoutUrl : String
    , wordsUrl : String
    , currentUserProfileUrl : String
    , progressUrl : String
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


type alias Filter =
    { pageNo : Int
    , searchText : String
    , chapter : Maybe String
    }



-- INIT


initialFilter =
    { pageNo = 0
    , searchText = ""
    , chapter = Nothing
    }
