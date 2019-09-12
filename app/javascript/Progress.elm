module Progress exposing (..)

import Array
import Browser
import Browser.Navigation exposing (load)
import Functions exposing (fullWord)
import Html exposing (Html, button, div, form, h1, input, label, option, select, span, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (attribute, class, placeholder, scope, selected, style, type_, value)
import Html.Events exposing (onClick, onInput)



-- MODEL


type alias Flags =
    { progresses : List Progress
    , urls : Urls
    }


type alias Model =
    { allProgresses : List Progress
    , viewProgresses : List Progress
    , filter : Filter
    , urls : Urls
    }


type alias Filter =
    { pageNo : Int
    , searchText : String
    , translated : TranslatedOption
    }


type alias Urls =
    { editTransactionUrl : String
    , csrfToken : String
    }


type alias Progress =
    { wordId : String
    , german : String
    , article : Maybe String
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



-- INIT


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { allProgresses = flags.progresses
      , viewProgresses = viewProgresses defaultFilter flags.progresses
      , filter = defaultFilter
      , urls = flags.urls
      }
    , Cmd.none
    )


defaultFilter : Filter
defaultFilter =
    { pageNo = 0
    , searchText = ""
    , translated = Yes
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
            , text "page nav"
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
                , tbody [] (List.map rowView model.viewProgresses)
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



-- MESSAGE


type Msg
    = SearchStringChanged String
    | ClearSearchText
    | ProgressClicked String
    | SelectTranslatedOption String



-- UPDATE


viewProgresses : Filter -> List Progress -> List Progress
viewProgresses filter progresses =
    let
        progressesPerPage =
            20

        translatedProgresses =
            case filter.translated of
                Any ->
                    progresses

                No ->
                    List.filter (\p -> not p.translated) progresses

                Yes ->
                    List.filter (\p -> p.translated) progresses

        filteredProgresses =
            case filter.searchText of
                "" ->
                    Array.fromList translatedProgresses

                searchString ->
                    Array.fromList (List.filter (\p -> String.contains searchString p.german) translatedProgresses)
    in
    Array.toList (Array.slice (filter.pageNo * progressesPerPage) progressesPerPage filteredProgresses)


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    let
        _ =
            Debug.log "message" message
    in
    case message of
        SearchStringChanged searchText ->
            let
                newFilter =
                    { searchText = searchText
                    , pageNo = 0
                    , translated = model.filter.translated
                    }

                newProgresses =
                    viewProgresses newFilter model.allProgresses
            in
            ( { model | filter = newFilter, viewProgresses = newProgresses }, Cmd.none )

        ClearSearchText ->
            let
                newFilter =
                    { searchText = ""
                    , pageNo = 0
                    , translated = model.filter.translated
                    }

                newProgresses =
                    viewProgresses newFilter model.allProgresses
            in
            ( { model | filter = newFilter, viewProgresses = newProgresses }, Cmd.none )

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
                    , pageNo = 0
                    , translated = translatedOption
                    }

                newProgresses =
                    viewProgresses newFilter model.allProgresses
            in
            ( { model | filter = newFilter, viewProgresses = newProgresses }, Cmd.none )



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
