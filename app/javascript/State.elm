module State exposing (..)

import List.Extra as ListExtra
import Url



-- TYPES


type alias AppState =
    { user : User
    , urls : Urls
    , words : List Word
    , filteredWords : List Word
    , filter : Filter
    , currentWordId : String
    , currentWordIndex : Maybe Int
    }


type alias User =
    { id : String
    , name : String
    }


type alias Urls =
    { csrfToken : String
    , logoutUrl : String
    , wordsUrl : String
    , currentUserProfileUrl : String
    , progressUrl : String
    , translationsUrl : String
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


type PaginationDirection
    = First
    | Previous
    | Next
    | Last



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


setWord : AppState -> Url.Url -> AppState
setWord state url =
    let
        currentWordId =
            case url.query of
                Nothing ->
                    ""

                Just wordId ->
                    String.right 36 wordId

        currentWordIndex =
            ListExtra.findIndex (\w -> w.id == currentWordId) state.words
    in
    { state | currentWordId = currentWordId, currentWordIndex = currentWordIndex }


setPagination : AppState -> PaginationDirection -> AppState
setPagination state direction =
    let
        newPageNo =
            case direction of
                First ->
                    1

                Previous ->
                    state.filter.pageNo - 1

                Next ->
                    state.filter.pageNo + 1

                Last ->
                    numberOfPages state

        newFilter =
            { searchText = state.filter.searchText
            , pageNo = newPageNo
            , level = state.filter.level
            }
    in
    { state | filter = newFilter, filteredWords = filteredWords newFilter state.words }


progressesPerPage : Int
progressesPerPage =
    20


numberOfPages : AppState -> Int
numberOfPages state =
    ceiling (toFloat (List.length state.filteredWords) / toFloat progressesPerPage)


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
