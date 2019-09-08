module Progress exposing (..)

import Browser
import Html exposing (Html, div, h1, span, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class, scope, style)



-- MODEL


type alias Model =
    { progresses : List Progress
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


init : Model -> ( Model, Cmd Msg )
init model =
    ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "row" ]
        [ div [ class "col-lg-12" ]
            [ div [ class "row align-items-center" ]
                [ div [ class "col-sm-4" ]
                    [ h1 [] [ text "Progress" ]
                    ]
                , div [ class "col-sm-8" ] [ text "word search here" ]
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
                , tbody [] (List.map rowView model.progresses)
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


noBreakSpace : Char
noBreakSpace =
    '✓'


learntView : Bool -> Html Msg
learntView learnt =
    case learnt of
        False ->
            text ""

        True ->
            text (String.fromChar noBreakSpace)


fullWord : Maybe String -> String -> String
fullWord maybeArticle word =
    case maybeArticle of
        Nothing ->
            word

        Just article ->
            article ++ " " ++ word



-- MESSAGE


type Msg
    = None



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- MAIN


main : Program Model Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
