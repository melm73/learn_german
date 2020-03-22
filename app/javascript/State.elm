module State exposing (..)

import Dict exposing (Dict)
import List.Extra as ListExtra
import Url



-- TYPES


type alias AppState =
    { user : User
    , urls : Urls
    , words : List Word
    , progresses : Dict String Progress
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
    , reviewsUrl : String
    }


type alias Word =
    { id : String
    , german : String
    , article : Maybe String
    , category : String
    , plural : Maybe String
    , level : Maybe Int
    }


type alias Progress =
    { wordId : String
    , translated : Bool
    , sentence : Maybe String
    , level : Int
    , timesReviewed : Int
    , lastReviewed : Maybe String
    , learnt : Bool
    }


type alias Filter =
    { pageNo : Int
    , searchText : String
    , level : Maybe Int
    , translated : Maybe Bool
    , learnt : Maybe Bool
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
    , translated = Nothing
    , learnt = Nothing
    }



-- SETTERS


clearFilterSearchText : AppState -> AppState
clearFilterSearchText state =
    let
        newFilter =
            { searchText = ""
            , pageNo = 1
            , level = state.filter.level
            , translated = state.filter.translated
            , learnt = state.filter.learnt
            }
    in
    { state | filter = newFilter, filteredWords = filteredWords newFilter state.words state.progresses }


setFilterSearchText : AppState -> String -> AppState
setFilterSearchText state searchText =
    let
        newFilter =
            { searchText = searchText
            , pageNo = 1
            , level = state.filter.level
            , translated = state.filter.translated
            , learnt = state.filter.learnt
            }
    in
    { state | filter = newFilter, filteredWords = filteredWords newFilter state.words state.progresses }


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
            , translated = state.filter.translated
            , learnt = state.filter.learnt
            }
    in
    { state | filter = newFilter, filteredWords = filteredWords newFilter state.words state.progresses }


setFilterTranslated : AppState -> String -> AppState
setFilterTranslated state translated =
    let
        translatedValue =
            case translated of
                "Any" ->
                    Nothing

                "Yes" ->
                    Just True

                "No" ->
                    Just False

                _ ->
                    Nothing

        newFilter =
            { searchText = state.filter.searchText
            , pageNo = state.filter.pageNo
            , level = state.filter.level
            , translated = translatedValue
            , learnt = state.filter.learnt
            }
    in
    { state | filter = newFilter, filteredWords = filteredWords newFilter state.words state.progresses }


setFilterLearnt : AppState -> String -> AppState
setFilterLearnt state learnt =
    let
        learntValue =
            case learnt of
                "Any" ->
                    Nothing

                "Yes" ->
                    Just True

                "No" ->
                    Just False

                _ ->
                    Nothing

        newFilter =
            { searchText = state.filter.searchText
            , pageNo = state.filter.pageNo
            , level = state.filter.level
            , translated = state.filter.translated
            , learnt = learntValue
            }
    in
    { state | filter = newFilter, filteredWords = filteredWords newFilter state.words state.progresses }


setWords : AppState -> List Word -> AppState
setWords state words =
    { state | words = words, filteredWords = filteredWords state.filter words state.progresses }


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


setProgresses : AppState -> List Progress -> AppState
setProgresses state progresses =
    let
        progressesDict =
            Dict.fromList (List.map (\p -> ( p.wordId, p )) progresses)
    in
    { state | progresses = progressesDict, filteredWords = filteredWords state.filter state.words state.progresses }


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
            , translated = state.filter.translated
            , learnt = state.filter.learnt
            }
    in
    { state | filter = newFilter, filteredWords = filteredWords newFilter state.words state.progresses }


progressesPerPage : Int
progressesPerPage =
    20


numberOfPages : AppState -> Int
numberOfPages state =
    ceiling (toFloat (List.length state.filteredWords) / toFloat progressesPerPage)


filteredWords : Filter -> List Word -> Dict String Progress -> List Word
filteredWords filter words progresses =
    let
        levelWords =
            case filter.level of
                Nothing ->
                    words

                Just level ->
                    List.filter (isInLevel level) words

        translatedWords =
            case filter.translated of
                Nothing ->
                    levelWords

                Just translated ->
                    List.filter (isTranslated translated progresses) levelWords

        learntWords =
            case filter.learnt of
                Nothing ->
                    translatedWords

                Just learnt ->
                    List.filter (isLearnt learnt progresses) translatedWords
    in
    case filter.searchText of
        "" ->
            learntWords

        searchString ->
            List.filter (containsSearchString searchString) learntWords


isInLevel : Int -> Word -> Bool
isInLevel level word =
    case word.level of
        Nothing ->
            False

        Just wordLevel ->
            wordLevel == level


isTranslated : Bool -> Dict String Progress -> Word -> Bool
isTranslated translated progresses word =
    let
        progress =
            Dict.get word.id progresses
    in
    case progress of
        Nothing ->
            not translated

        Just _ ->
            translated


isLearnt : Bool -> Dict String Progress -> Word -> Bool
isLearnt learnt progresses word =
    let
        progress =
            Dict.get word.id progresses
    in
    case progress of
        Nothing ->
            False

        Just actualProgress ->
            actualProgress.learnt == learnt


containsSearchString : String -> Word -> Bool
containsSearchString searchString word =
    String.contains (String.toLower searchString) (String.toLower word.german)
