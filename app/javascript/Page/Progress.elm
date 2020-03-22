module Page.Progress exposing (..)

import Array
import Dict exposing (Dict)
import Functions exposing (fullWord)
import Html exposing (Html, a, button, div, form, h1, input, label, li, nav, option, select, span, table, tbody, td, text, th, thead, tr, ul)
import Html.Attributes exposing (class, classList, href, placeholder, scope, selected, type_, value)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as Decoder
import ProgressPieChart
import State exposing (AppState, Progress)



---- MODEL


type alias Model =
    {}


init : AppState -> ( Model, Cmd Msg )
init state =
    ( {}
    , getProgressRequest state
    )



-- UPDATE


type Msg
    = HandleProgressResponse (Result Http.Error (List Progress))
    | SearchStringChanged String
    | ClearSearchText
    | SelectLearntOption String
    | SelectTranslatedOption String
    | SelectLevelOption String
    | PaginationClicked State.PaginationDirection


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        HandleProgressResponse (Err error) ->
            let
                _ =
                    Debug.log "GET progresses error" error
            in
            ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


getProgressRequest : AppState -> Cmd Msg
getProgressRequest state =
    Http.request
        { method = "GET"
        , headers = [ Http.header "X-CSRF-Token" state.urls.csrfToken, Http.header "Accept" "application/json" ]
        , url = state.urls.progressUrl
        , body = Http.emptyBody
        , expect = Http.expectJson HandleProgressResponse (Decoder.list progressDecoder)
        , timeout = Nothing
        , tracker = Nothing
        }


progressDecoder : Decoder.Decoder Progress
progressDecoder =
    Decoder.map7 Progress
        (Decoder.field "wordId" Decoder.string)
        (Decoder.field "translated" Decoder.bool)
        (Decoder.field "sentence" (Decoder.nullable Decoder.string))
        (Decoder.field "level" Decoder.int)
        (Decoder.field "timesReviewed" Decoder.int)
        (Decoder.field "lastReviewed" (Decoder.nullable Decoder.string))
        (Decoder.field "learnt" Decoder.bool)


progressToDict : List Progress -> Dict String Progress
progressToDict progresses =
    Dict.fromList (List.map (\p -> ( p.wordId, p )) progresses)



--VIEW


view : Model -> AppState -> Html Msg
view model state =
    div [ class "row" ]
        [ div [ class "col-lg-9" ]
            [ div [ class "row align-items-center" ]
                [ div [ class "col-sm-4" ] [ h1 [] [ text "Progress" ] ] ]
            , div [ class "row" ]
                [ div [ class "col-sm-4" ] [ paginationView model state ]
                , div [ class "col-sm-8" ] [ searchView model state ]
                ]
            , table [ class "table table-striped" ]
                [ thead [ class "thead-dark" ]
                    [ tr []
                        [ th [ scope "col" ] []
                        , th [ scope "col" ] [ text "GERMAN", sortView ]
                        , th [ scope "col", class "text-center" ] [ text "TYPE" ]
                        , th [ scope "col", class "text-center" ] [ text "LEVEL" ]
                        , th [ scope "col", class "text-center" ] [ text "REVIEWS" ]
                        ]
                    ]
                , tbody [] (List.map (rowView state.progresses) (paginated state state.filteredWords))
                ]
            ]
        , div [ class "col-lg-3" ]
            [ ProgressPieChart.view (progressStats model state) ]
        ]


paginated : AppState -> List State.Word -> List State.Word
paginated state words =
    let
        sliceFrom =
            (state.filter.pageNo - 1) * State.progressesPerPage

        sliceTo =
            state.filter.pageNo * State.progressesPerPage
    in
    Array.toList (Array.slice sliceFrom sliceTo (Array.fromList words))


sortView : Html Msg
sortView =
    text (" " ++ String.fromChar sortUp)


sortUp : Char
sortUp =
    '▲'


sortDown : Char
sortDown =
    '▼'


rowView : Dict String Progress -> State.Word -> Html Msg
rowView progresses word =
    let
        progress =
            Dict.get word.id progresses

        sentence =
            case progress of
                Nothing ->
                    ""

                Just actualProgress ->
                    Maybe.withDefault "" actualProgress.sentence

        level =
            case progress of
                Nothing ->
                    0

                Just actualProgress ->
                    actualProgress.level

        wordLevel =
            case word.level of
                Nothing ->
                    ""

                Just actualLevel ->
                    String.fromInt actualLevel
    in
    tr []
        [ td [ class "text-center align-middle text-muted" ] [ text wordLevel ]
        , td []
            [ div [ class "lead" ] [ wordView word ]
            , div [ class "text-muted" ] [ text sentence ]
            ]
        , td [ class "text-center align-middle" ] [ text word.category ]
        , td [ class "text-center align-middle" ] [ levelView level ]
        , td [] (reviewView progress)
        ]


wordView word =
    let
        plural =
            case word.plural of
                Nothing ->
                    ""

                Just actualPlural ->
                    " / die " ++ actualPlural
    in
    a [ href ("/translation?wordId=" ++ word.id) ] [ text (fullWord word.article word.german ++ plural) ]


reviewView : Maybe Progress -> List (Html Msg)
reviewView progress =
    case progress of
        Nothing ->
            [ text "" ]

        Just actualProgress ->
            [ div [ class "text-center align-middle" ]
                [ case actualProgress.timesReviewed of
                    0 ->
                        text ""

                    _ ->
                        text (String.fromInt actualProgress.timesReviewed)
                ]
            , div [ class "text-center align-middle text-muted" ]
                [ text (Maybe.withDefault "" actualProgress.lastReviewed)
                ]
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


searchView : Model -> AppState -> Html Msg
searchView model state =
    form [ class "search-form form-inline float-lg-right" ]
        [ div [ class "form-group pr-2" ]
            [ label [ class "pr-1" ] [ text "Learnt?" ]
            , select [ class "form-control", onInput SelectLearntOption ]
                [ option [ selected (state.filter.learnt == Nothing), value "Any" ] [ text "Any" ]
                , option [ selected (state.filter.learnt == Just True), value "Yes" ] [ text "Yes" ]
                , option [ selected (state.filter.learnt == Just False), value "No" ] [ text "No" ]
                ]
            ]
        , div [ class "form-group pr-2" ]
            [ label [ class "pr-1" ] [ text "Translated?" ]
            , select [ class "form-control", onInput SelectTranslatedOption ]
                [ option [ selected (state.filter.translated == Nothing), value "Any" ] [ text "Any" ]
                , option [ selected (state.filter.translated == Just True), value "Yes" ] [ text "Yes" ]
                , option [ selected (state.filter.translated == Just False), value "No" ] [ text "No" ]
                ]
            ]
        , div [ class "form-group pr-2" ]
            [ label [ class "pr-1" ] [ text "Level" ]
            , select [ class "form-control", onInput SelectLevelOption ]
                [ option [ selected (state.filter.level == Nothing), value "Any" ] [ text "Any" ]
                , option [ selected (state.filter.level == Just 1), value "1" ] [ text "1" ]
                , option [ selected (state.filter.level == Just 2), value "2" ] [ text "2" ]
                , option [ selected (state.filter.level == Just 3), value "3" ] [ text "3" ]
                , option [ selected (state.filter.level == Just 4), value "4" ] [ text "4" ]
                , option [ selected (state.filter.level == Just 5), value "5" ] [ text "5" ]
                ]
            ]
        , div [ class "form-group position-relative" ]
            [ input
                [ type_ "text"
                , class "form-control"
                , placeholder "search..."
                , value state.filter.searchText
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


paginationView : Model -> AppState -> Html Msg
paginationView model state =
    nav []
        [ ul [ class "pagination" ]
            [ paginationFirstView state
            , paginationPreviousView state
            , paginationPageView model state
            , paginationNextView model state
            , paginationLastView model state
            ]
        ]


paginationFirstView : AppState -> Html Msg
paginationFirstView state =
    li [ classList [ ( "page-item", True ), ( "disabled", state.filter.pageNo == 1 ) ] ]
        [ button [ class "page-link", onClick (PaginationClicked State.First) ] [ text (String.fromChar doubleChevronLeft) ] ]


paginationPreviousView : AppState -> Html Msg
paginationPreviousView state =
    li [ classList [ ( "page-item", True ), ( "disabled", state.filter.pageNo == 1 ) ] ]
        [ button [ class "page-link", onClick (PaginationClicked State.Previous) ] [ text (String.fromChar singleChevronLeft) ] ]


paginationPageView : Model -> AppState -> Html Msg
paginationPageView model state =
    li [ class "page-item disabled" ]
        [ button [ class "page-link" ] [ text ("Page " ++ String.fromInt state.filter.pageNo ++ " of " ++ String.fromInt (State.numberOfPages state)) ] ]


paginationNextView : Model -> AppState -> Html Msg
paginationNextView model state =
    li [ classList [ ( "page-item", True ), ( "disabled", state.filter.pageNo == State.numberOfPages state ) ] ]
        [ button [ class "page-link", onClick (PaginationClicked State.Next) ] [ text (String.fromChar singleChevronRight) ] ]


paginationLastView : Model -> AppState -> Html Msg
paginationLastView model state =
    li [ classList [ ( "page-item", True ), ( "disabled", state.filter.pageNo == State.numberOfPages state ) ] ]
        [ button [ class "page-link", onClick (PaginationClicked State.Last) ] [ text (String.fromChar doubleChevronRight) ] ]



-- STATS


progressStats : Model -> AppState -> ProgressPieChart.Stats
progressStats model state =
    let
        filteredProgresses =
            Dict.filter (\wordId -> \progress -> List.any (\word -> word.id == wordId) state.filteredWords) state.progresses

        totalCount =
            List.length state.filteredWords

        learntCount =
            Dict.size (Dict.filter (\wordId -> \progress -> progress.learnt) filteredProgresses)

        translatedCount =
            Dict.size (Dict.filter (\wordId -> \progress -> progress.translated) filteredProgresses) - learntCount

        notSeenCount =
            totalCount - translatedCount - learntCount
    in
    { percentageLearnt = toFloat learntCount / toFloat totalCount * 100
    , percentageTranslated = toFloat translatedCount / toFloat totalCount * 100
    , percentageNotSeen = toFloat notSeenCount / toFloat totalCount * 100
    , numberOfWords = totalCount
    }
