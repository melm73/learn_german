module Progress exposing (..)

import Array
import Browser
import Browser.Navigation exposing (load)
import Functions exposing (fullWord)
import Html exposing (Html, button, div, form, h1, input, label, li, nav, option, select, span, table, tbody, td, text, th, thead, tr, ul)
import Html.Attributes exposing (attribute, class, classList, placeholder, scope, selected, style, type_, value)
import Html.Events exposing (onClick, onInput)



-- MODEL


type alias Flags =
    { progresses : List Progress
    , urls : Urls
    }


type alias Model =
    { allProgresses : List Progress
    , filteredProgresses : List Progress
    , filter : Filter
    , urls : Urls
    }


type alias Filter =
    { pageNo : Int
    , searchText : String
    , translated : TranslatedOption
    , chapter : Maybe String
    }


type alias Urls =
    { editTransactionUrl : String
    , csrfToken : String
    }


type alias Progress =
    { wordId : String
    , german : String
    , article : Maybe String
    , chapter : Maybe String
    , translated : Bool
    , sentence : Maybe String
    , level : Int
    , timesReviewed : Int
    , lastReview : Maybe String
    , learnt : Bool
    }


type TranslatedOption
    = Any
    | No
    | Yes


type PaginationDirection
    = First
    | Previous
    | Next
    | Last



-- INIT


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { allProgresses = flags.progresses
      , filteredProgresses = filteredProgresses defaultFilter flags.progresses
      , filter = defaultFilter
      , urls = flags.urls
      }
    , Cmd.none
    )


defaultFilter : Filter
defaultFilter =
    { pageNo = 1
    , searchText = ""
    , translated = Yes
    , chapter = Nothing
    }



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "row" ]
        [ div [ class "col-lg-12" ]
            [ div [ class "row align-items-center" ]
                [ div [ class "col-sm-4" ]
                    [ h1 [] [ text "Progress" ]
                    ]
                , div [ class "col-sm-8" ] [ searchView model ]
                ]
            , paginationView model
            , table [ class "table table-hover" ]
                [ thead [ class "thead-dark" ]
                    [ tr []
                        [ th [ scope "col" ] [ text "GERMAN" ]
                        , th [ scope "col", class "text-center" ] [ text "LEVEL" ]
                        , th [ scope "col", class "text-center" ] [ text "NO. REVIEWS" ]
                        , th [ scope "col", class "text-center" ] [ text "LAST REVIEWED" ]
                        , th [ scope "col", class "text-center" ] [ text "LEARNT" ]
                        ]
                    ]
                , tbody [] (List.map rowView (viewProgresses model))
                ]
            ]
        ]


rowView : Progress -> Html Msg
rowView progress =
    tr [ onClick (ProgressClicked progress.wordId) ]
        [ td []
            [ div [ class "lead" ] [ text (fullWord progress.article progress.german) ]
            , div [ class "text-muted" ] [ text (Maybe.withDefault "" progress.sentence) ]
            ]
        , td [ class "text-center align-middle" ] [ levelView progress.level ]
        , td [ class "text-center align-middle" ] [ text (String.fromInt progress.timesReviewed) ]
        , td [ class "text-center align-middle" ] [ text (Maybe.withDefault "" progress.lastReview) ]
        , td [ class "text-center align-middle" ] [ learntView progress.learnt ]
        ]


levelView : Int -> Html Msg
levelView level =
    div [ class "gauge" ]
        (List.append
            (List.repeat level (span [ class "dot filled" ] []))
            (List.repeat (5 - level) (span [ class "dot hollow" ] []))
        )


tickMark : Char
tickMark =
    '✓'


learntView : Bool -> Html Msg
learntView learnt =
    case learnt of
        False ->
            text ""

        True ->
            text (String.fromChar tickMark)


crossChar : Char
crossChar =
    '✕'


searchView : Model -> Html Msg
searchView model =
    form [ class "search-form form-inline float-lg-right" ]
        [ div [ class "form-group pr-3" ]
            [ label [ class "pr-2" ] [ text "Translated?" ]
            , select [ class "form-control", onInput SelectTranslatedOption ]
                [ option [ selected (model.filter.translated == Any), value "Any" ] [ text "Any" ]
                , option [ selected (model.filter.translated == Yes), value "Yes" ] [ text "Yes" ]
                , option [ selected (model.filter.translated == No), value "No" ] [ text "No" ]
                ]
            ]
        , div [ class "form-group pr-3" ]
            [ label [ class "pr-2" ] [ text "Chapter" ]
            , select [ class "form-control", onInput SelectChapterOption ]
                [ option [ selected (model.filter.chapter == Nothing), value "Any" ] [ text "Any" ]
                , option [ selected (model.filter.chapter == Just "1.1"), value "1.1" ] [ text "1.1" ]
                , option [ selected (model.filter.chapter == Just "1.2"), value "1.2" ] [ text "1.2" ]
                , option [ selected (model.filter.chapter == Just "1.3"), value "1.3" ] [ text "1.3" ]
                ]
            ]
        , div [ class "form-group position-relative" ]
            [ input
                [ type_ "text"
                , class "form-control"
                , placeholder "search..."
                , value model.filter.searchText
                , onInput SearchStringChanged
                ]
                []
            , span [ class "form-clear", onClick ClearSearchText ] [ text (String.fromChar crossChar) ]
            ]
        ]


singleChevronLeft : Char
singleChevronLeft =
    '‹'


doubleChevronLeft : Char
doubleChevronLeft =
    '«'


singleChevronRight : Char
singleChevronRight =
    '›'


doubleChevronRight : Char
doubleChevronRight =
    '»'


paginationView : Model -> Html Msg
paginationView model =
    nav []
        [ ul [ class "pagination" ]
            [ paginationFirstView model
            , paginationPreviousView model
            , paginationPageView model
            , paginationNextView model
            , paginationLastView model
            ]
        ]


paginationFirstView : Model -> Html Msg
paginationFirstView model =
    li [ classList [ ( "page-item", True ), ( "disabled", model.filter.pageNo == 1 ) ] ]
        [ button [ class "page-link", onClick (PaginationClicked First) ] [ text (String.fromChar doubleChevronLeft) ] ]


paginationPreviousView : Model -> Html Msg
paginationPreviousView model =
    li [ classList [ ( "page-item", True ), ( "disabled", model.filter.pageNo == 1 ) ] ]
        [ button [ class "page-link", onClick (PaginationClicked Previous) ] [ text (String.fromChar singleChevronLeft) ] ]


paginationPageView : Model -> Html Msg
paginationPageView model =
    li [ class "page-item disabled" ] [ button [ class "page-link" ] [ text ("Page " ++ String.fromInt model.filter.pageNo ++ " of " ++ String.fromInt (numberOfPages model)) ] ]


paginationNextView : Model -> Html Msg
paginationNextView model =
    li [ classList [ ( "page-item", True ), ( "disabled", model.filter.pageNo == numberOfPages model ) ] ]
        [ button [ class "page-link", onClick (PaginationClicked Next) ] [ text (String.fromChar singleChevronRight) ] ]


paginationLastView : Model -> Html Msg
paginationLastView model =
    li [ classList [ ( "page-item", True ), ( "disabled", model.filter.pageNo == numberOfPages model ) ] ]
        [ button [ class "page-link", onClick (PaginationClicked Last) ] [ text (String.fromChar doubleChevronRight) ] ]



-- MESSAGE


type Msg
    = SearchStringChanged String
    | ClearSearchText
    | ProgressClicked String
    | SelectTranslatedOption String
    | SelectChapterOption String
    | PaginationClicked PaginationDirection



-- UPDATE


numberOfPages : Model -> Int
numberOfPages model =
    ceiling (toFloat (List.length model.filteredProgresses) / toFloat progressesPerPage)


progressesPerPage : Int
progressesPerPage =
    20


isInChapter : String -> Progress -> Bool
isInChapter chapter progress =
    case progress.chapter of
        Nothing ->
            False

        Just progressChapter ->
            progressChapter == chapter


filteredProgresses : Filter -> List Progress -> List Progress
filteredProgresses filter progresses =
    let
        translatedProgresses =
            case filter.translated of
                Any ->
                    progresses

                No ->
                    List.filter (\p -> not p.translated) progresses

                Yes ->
                    List.filter (\p -> p.translated) progresses

        chapterProgresses =
            case filter.chapter of
                Nothing ->
                    translatedProgresses

                Just chapter ->
                    List.filter (isInChapter chapter) translatedProgresses
    in
    case filter.searchText of
        "" ->
            chapterProgresses

        searchString ->
            List.filter (\p -> String.contains searchString p.german) chapterProgresses


viewProgresses : Model -> List Progress
viewProgresses model =
    let
        sliceFrom =
            (model.filter.pageNo - 1) * progressesPerPage

        sliceTo =
            model.filter.pageNo * progressesPerPage
    in
    Array.toList (Array.slice sliceFrom sliceTo (Array.fromList model.filteredProgresses))


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        SearchStringChanged searchText ->
            let
                newFilter =
                    { searchText = searchText
                    , pageNo = 1
                    , translated = model.filter.translated
                    , chapter = model.filter.chapter
                    }

                newProgresses =
                    filteredProgresses newFilter model.allProgresses
            in
            ( { model | filter = newFilter, filteredProgresses = newProgresses }, Cmd.none )

        ClearSearchText ->
            let
                newFilter =
                    { searchText = ""
                    , pageNo = 1
                    , translated = model.filter.translated
                    , chapter = model.filter.chapter
                    }

                newProgresses =
                    filteredProgresses newFilter model.allProgresses
            in
            ( { model | filter = newFilter, filteredProgresses = newProgresses }, Cmd.none )

        ProgressClicked wordId ->
            ( model, load (model.urls.editTransactionUrl ++ "?word_id=" ++ wordId) )

        SelectTranslatedOption option ->
            let
                translatedOption =
                    case option of
                        "Any" ->
                            Any

                        "Yes" ->
                            Yes

                        "No" ->
                            No

                        _ ->
                            Any

                newFilter =
                    { searchText = model.filter.searchText
                    , pageNo = 1
                    , translated = translatedOption
                    , chapter = model.filter.chapter
                    }

                newProgresses =
                    filteredProgresses newFilter model.allProgresses
            in
            ( { model | filter = newFilter, filteredProgresses = newProgresses }, Cmd.none )

        PaginationClicked direction ->
            let
                newPageNo =
                    case direction of
                        First ->
                            1

                        Previous ->
                            model.filter.pageNo - 1

                        Next ->
                            model.filter.pageNo + 1

                        Last ->
                            numberOfPages model

                newFilter =
                    { searchText = model.filter.searchText
                    , pageNo = newPageNo
                    , translated = model.filter.translated
                    , chapter = model.filter.chapter
                    }

                newProgresses =
                    filteredProgresses newFilter model.allProgresses
            in
            ( { model | filter = newFilter, filteredProgresses = newProgresses }, Cmd.none )

        SelectChapterOption option ->
            let
                selectedChapter =
                    case option of
                        "Any" ->
                            Nothing

                        _ ->
                            Just option

                newFilter =
                    { searchText = model.filter.searchText
                    , pageNo = 1
                    , translated = model.filter.translated
                    , chapter = selectedChapter
                    }

                newProgresses =
                    filteredProgresses newFilter model.allProgresses
            in
            ( { model | filter = newFilter, filteredProgresses = newProgresses }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
