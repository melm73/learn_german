module State exposing (..)

-- TYPES


type alias AppState =
    { user : User
    , urls : Urls
    , words : List Word
    , filteredWords : List Word
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
    , article : Maybe String
    , category : String
    , plural : Maybe String
    , level : Maybe Int
    }


type alias Filter =
    { pageNo : Int
    , searchText : String
    , level : Maybe Int
    }



-- INIT


initialFilter =
    { pageNo = 1
    , searchText = ""
    , level = Nothing
    }



-- SETTERS


clearFilterSearchText : AppState -> AppState
clearFilterSearchText state =
    let
        newFilter =
            { searchText = ""
            , pageNo = 1
            , level = state.filter.level
            }
    in
    { state | filter = newFilter, filteredWords = filteredWords newFilter state.words }


setFilterSearchText : AppState -> String -> AppState
setFilterSearchText state searchText =
    let
        newFilter =
            { searchText = searchText
            , pageNo = 1
            , level = state.filter.level
            }
    in
    { state | filter = newFilter, filteredWords = filteredWords newFilter state.words }


setFilterLevel : AppState -> String -> AppState
setFilterLevel state option =
    let
        selectedLevel =
            case option of
                "Any" ->
                    Nothing

                _ ->
                    String.toInt (Maybe.withDefault "0" (Just option))

        newFilter =
            { searchText = state.filter.searchText
            , pageNo = 1
            , level = selectedLevel
            }
    in
    { state | filter = newFilter, filteredWords = filteredWords newFilter state.words }


setWords : AppState -> List Word -> AppState
setWords state words =
    { state | words = words, filteredWords = filteredWords state.filter words }



-- WORDS


filteredWords : Filter -> List Word -> List Word
filteredWords filter words =
    let
        levelWords =
            case filter.level of
                Nothing ->
                    words

                Just level ->
                    List.filter (isInLevel level) words
    in
    case filter.searchText of
        "" ->
            levelWords

        searchString ->
            List.filter (\w -> String.contains (String.toLower searchString) (String.toLower w.german)) levelWords


isInLevel : Int -> Word -> Bool
isInLevel level word =
    case word.level of
        Nothing ->
            False

        Just wordLevel ->
            wordLevel == level
