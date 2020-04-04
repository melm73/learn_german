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
    , duolingoLevel : Maybe Int
    , goetheLevel : Maybe String
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
    , duolingoLevel : Maybe Int
    , goetheLevel : Maybe String
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
    , duolingoLevel = Nothing
    , goetheLevel = Nothing
    , translated = Nothing
    , learnt = Nothing
    }



-- SETTERS


clearFilterSearchText : AppState -> AppState
clearFilterSearchText state =
    let
        currentFilter =
            state.filter

        newFilter =
            { currentFilter
                | searchText = ""
                , pageNo = 1
            }
    in
    { state | filter = newFilter, filteredWords = filteredWords newFilter state.words state.progresses }


setFilterSearchText : AppState -> String -> AppState
setFilterSearchText state searchText =
    let
        currentFilter =
            state.filter

        newFilter =
            { currentFilter
                | searchText = searchText
                , pageNo = 1
            }
    in
    { state | filter = newFilter, filteredWords = filteredWords newFilter state.words state.progresses }


setFilterLevel : AppState -> String -> AppState
setFilterLevel state option =
    let
        ( duolingoLevel, goetheLevel ) =
            case option of
                "Any" ->
                    ( Nothing, Nothing )

                "A1" ->
                    ( Nothing, Just "A1" )

                _ ->
                    ( String.toInt (Maybe.withDefault "0" (Just option)), Nothing )

        currentFilter =
            state.filter

        newFilter =
            { currentFilter
                | pageNo = 1
                , duolingoLevel = duolingoLevel
                , goetheLevel = goetheLevel
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

        currentFilter =
            state.filter

        newFilter =
            { currentFilter
                | translated = translatedValue
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

        currentFilter =
            state.filter

        newFilter =
            { currentFilter
                | learnt = learntValue
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

        currentFilter =
            state.filter

        newFilter =
            { currentFilter
                | pageNo = newPageNo
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
        duolingoLevelWords =
            case filter.duolingoLevel of
                Nothing ->
                    words

                Just duolingoLevel ->
                    List.filter (isInDuolingoLevel duolingoLevel) words

        goetheLevelWords =
            case filter.goetheLevel of
                Nothing ->
                    duolingoLevelWords

                Just goetheLevel ->
                    List.filter (isInGoetheLevel goetheLevel) duolingoLevelWords

        translatedWords =
            case filter.translated of
                Nothing ->
                    goetheLevelWords

                Just translated ->
                    List.filter (isTranslated translated progresses) goetheLevelWords

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


isInDuolingoLevel : Int -> Word -> Bool
isInDuolingoLevel level word =
    case word.duolingoLevel of
        Nothing ->
            False

        Just wordLevel ->
            wordLevel == level


isInGoetheLevel : String -> Word -> Bool
isInGoetheLevel level word =
    case word.goetheLevel of
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
