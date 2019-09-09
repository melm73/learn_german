module Progress exposing (..)

import Array
import Browser
import Html exposing (Html, button, div, form, h1, input, span, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class, placeholder, scope, style, type_, value)
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
    }


type alias Urls =
    { csrfToken : String
    }


type alias Progress =
    { id : String
    , german : String
    , article : Maybe String
    , sentence : Maybe String
    , level : Int
    , timesReviewed : Int
    , lastReview : Maybe String
    , learnt : Bool
    }



-- INIT


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { allProgresses = flags.progresses
      , viewProgresses = viewProgresses "" 0 flags.progresses
      , filter = { pageNo = 0, searchText = "" }
      , urls = flags.urls
      }
    , Cmd.none
    )



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
    tr []
        [ td []
            [ div [ class "lead" ] [ text (fullWord progress.article progress.german) ]
            , div [ class "text-muted" ] [ text (Maybe.withDefault "" progress.sentence) ]
            ]
        , td [ class "text-center" ] [ levelView progress.level ]
        , td [ class "text-center" ] [ text (String.fromInt progress.timesReviewed) ]
        , td [ class "text-center" ] [ text (Maybe.withDefault "" progress.lastReview) ]
        , td [ class "text-center" ] [ learntView progress.learnt ]
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
        [ div [ class "form-group position-relative" ]
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



-- FUNCTIONS


fullWord : Maybe String -> String -> String
fullWord maybeArticle word =
    case maybeArticle of
        Nothing ->
            word

        Just article ->
            article ++ " " ++ word



-- MESSAGE


type Msg
    = SearchStringChanged String
    | ClearSearchText



-- UPDATE


viewProgresses : String -> Int -> List Progress -> List Progress
viewProgresses searchText pageNo progresses =
    let
        progressesPerPage =
            5

        filteredProgresses =
            case searchText of
                "" ->
                    Array.fromList progresses

                searchString ->
                    Array.fromList (List.filter (\p -> String.contains searchString p.german) progresses)
    in
    Array.toList (Array.slice (pageNo * progressesPerPage) progressesPerPage filteredProgresses)


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        SearchStringChanged searchText ->
            let
                newProgresses =
                    viewProgresses searchText 0 model.allProgresses

                newFilter =
                    { searchText = searchText
                    , pageNo = 0
                    }
            in
            ( { model | filter = newFilter, viewProgresses = newProgresses }, Cmd.none )

        ClearSearchText ->
            let
                newProgresses =
                    viewProgresses "" 0 model.allProgresses

                newFilter =
                    { searchText = ""
                    , pageNo = 0
                    }
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
