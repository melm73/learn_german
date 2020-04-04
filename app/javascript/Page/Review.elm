module Page.Review exposing (..)

import Browser.Dom as Dom
import Functions exposing (fullWord)
import Html exposing (Html, button, div, form, h1, h2, h5, input, label, option, select, small, strong, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class, for, id, required, scope, selected, type_, value)
import Html.Attributes.Aria exposing (ariaDescribedby)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Http
import Json.Decode as Decoder
import List.Extra as ListExtra
import State exposing (AppState)
import Task



---- MODEL


type alias Model =
    { reviewState : ReviewState
    , reviewLevel : Maybe Int
    , reviewCount : Int
    , remainingReviews : List Review
    , currentReview : Maybe Review
    , currentTranslation : String
    , translationState : Maybe Bool
    , results : List TranslationResult
    , urls : State.Urls
    }


type ReviewState
    = SelectingOptions
    | FetchingReviews
    | Reviewing
    | Finished
    | Error


type alias Review =
    { translation : Translation
    , word : Word
    }


type alias Translation =
    { id : String
    , userId : String
    , translation : String
    , sentence : Maybe String
    }


type alias Word =
    { id : String
    , german : String
    , article : Maybe String
    , category : Maybe String
    }


type alias TranslationResult =
    { german : String
    , translation : String
    , reviewTranslation : String
    , correct : Bool
    }



-- INIT


init : AppState -> ( Model, Cmd Msg )
init state =
    ( { reviewState = SelectingOptions
      , reviewLevel = state.filter.duolingoLevel
      , reviewCount = 10
      , remainingReviews = []
      , currentReview = Nothing
      , currentTranslation = ""
      , translationState = Nothing
      , results = []
      , urls = state.urls
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = StartReviewClicked
    | HandleGetReviewsResponse (Result Http.Error (List Review))
    | SetReviewTranslation String
    | CheckButtonClicked
    | NextButtonClicked
    | HandlePostReviewResponse (Result Http.Error ())
    | SelectLevelOption String
    | SelectCountOption String
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        StartReviewClicked ->
            ( { model | reviewState = FetchingReviews }, getReviewsRequest model )

        SelectLevelOption level ->
            let
                selectedLevel =
                    case level of
                        "Any" ->
                            Nothing

                        _ ->
                            String.toInt (Maybe.withDefault "0" (Just level))
            in
            ( { model | reviewLevel = selectedLevel }, Cmd.none )

        SelectCountOption count ->
            let
                selectedCount =
                    Maybe.withDefault 10 (String.toInt count)
            in
            ( { model | reviewCount = selectedCount }, Cmd.none )

        HandleGetReviewsResponse (Ok reviews) ->
            let
                ( first, rest ) =
                    case reviews of
                        [] ->
                            ( Nothing, [] )

                        x :: xs ->
                            ( Just x, xs )
            in
            ( { model | reviewState = Reviewing, currentReview = first, remainingReviews = rest }, focusOn "inputTranslation" )

        HandleGetReviewsResponse (Err result) ->
            ( { model | reviewState = Error }, Cmd.none )

        SetReviewTranslation translation ->
            ( { model | currentTranslation = translation }, Cmd.none )

        CheckButtonClicked ->
            let
                ( correct, cmd ) =
                    case model.currentReview of
                        Nothing ->
                            ( Nothing, Cmd.none )

                        Just review ->
                            case model.currentTranslation of
                                "" ->
                                    ( Nothing, Cmd.none )

                                translation ->
                                    ( Just (translation == fullWord review.word.article review.word.german), focusOn "nextButton" )
            in
            ( { model | translationState = correct }, cmd )

        NextButtonClicked ->
            let
                ( cmd, results ) =
                    case ( model.currentReview, model.translationState ) of
                        ( Nothing, _ ) ->
                            ( Cmd.none, model.results )

                        ( Just review, Nothing ) ->
                            ( Cmd.none, model.results )

                        ( Just review, Just correct ) ->
                            ( postReviewRequest model review correct, addResult review correct model.currentTranslation model.results )
            in
            ( { model | results = results }, cmd )

        HandlePostReviewResponse (Ok _) ->
            let
                ( first, rest, reviewState ) =
                    case model.remainingReviews of
                        [] ->
                            ( Nothing, [], Finished )

                        x :: xs ->
                            ( Just x, xs, Reviewing )
            in
            ( { model | reviewState = reviewState, currentReview = first, remainingReviews = rest, currentTranslation = "", translationState = Nothing }, focusOn "inputTranslation" )

        HandlePostReviewResponse (Err _) ->
            ( { model | reviewState = Error }, Cmd.none )


addResult : Review -> Bool -> String -> List TranslationResult -> List TranslationResult
addResult review correct translation results =
    List.append
        [ { german = fullWord review.word.article review.word.german
          , translation = review.translation.translation
          , reviewTranslation = translation
          , correct = correct
          }
        ]
        results


getReviewsRequest : Model -> Cmd Msg
getReviewsRequest model =
    let
        queryParams =
            case model.reviewLevel of
                Nothing ->
                    "?count=" ++ String.fromInt model.reviewCount

                Just level ->
                    "?level=" ++ String.fromInt level ++ "&count=" ++ String.fromInt model.reviewCount
    in
    Http.request
        { method = "GET"
        , headers = [ Http.header "X-CSRF-Token" model.urls.csrfToken ]
        , url = model.urls.reviewsUrl ++ queryParams
        , body = Http.emptyBody
        , expect = Http.expectJson HandleGetReviewsResponse (Decoder.list reviewDecoder)
        , timeout = Nothing
        , tracker = Nothing
        }


postReviewRequest : Model -> Review -> Bool -> Cmd Msg
postReviewRequest model review correct =
    let
        correctString =
            case correct of
                True ->
                    "1"

                False ->
                    "0"
    in
    Http.request
        { method = "POST"
        , headers = [ Http.header "X-CSRF-Token" model.urls.csrfToken ]
        , url = model.urls.reviewsUrl ++ "?translation_id=" ++ review.translation.id ++ "&correct=" ++ correctString
        , body = Http.emptyBody
        , expect = Http.expectWhatever HandlePostReviewResponse
        , timeout = Nothing
        , tracker = Nothing
        }


reviewDecoder : Decoder.Decoder Review
reviewDecoder =
    Decoder.map2 Review
        (Decoder.field "translation" translationDecoder)
        (Decoder.field "word" wordDecoder)


translationDecoder : Decoder.Decoder Translation
translationDecoder =
    Decoder.map4 Translation
        (Decoder.field "id" Decoder.string)
        (Decoder.field "user_id" Decoder.string)
        (Decoder.field "translation" Decoder.string)
        (Decoder.field "sentence" (Decoder.nullable Decoder.string))


wordDecoder : Decoder.Decoder Word
wordDecoder =
    Decoder.map4 Word
        (Decoder.field "id" Decoder.string)
        (Decoder.field "german" Decoder.string)
        (Decoder.field "article" (Decoder.nullable Decoder.string))
        (Decoder.field "category" (Decoder.nullable Decoder.string))


focusOn : String -> Cmd Msg
focusOn target =
    Task.attempt (\_ -> NoOp) (Dom.focus target)



-- VIEW


view : Model -> AppState -> Html Msg
view model state =
    case model.reviewState of
        SelectingOptions ->
            optionsView model

        FetchingReviews ->
            div [] [ text "please wait... fetching" ]

        Reviewing ->
            reviewView model

        Finished ->
            resultsView model.results

        Error ->
            div [] [ text "something went wrong" ]


optionsView : Model -> Html Msg
optionsView model =
    div [ class "row" ]
        [ div [ class "col-sm-6 offset-sm-3" ]
            [ div [ class "card" ]
                [ h5 [ class "card-header" ] [ text "Review options" ]
                , div [ class "card-body " ]
                    [ div [ class "row form-group" ]
                        [ label [ class "col-sm-6 control-label text-right" ] [ text "translated words only" ] ]
                    , div [ class "row form-group" ]
                        [ label [ class "col-sm-6 control-label text-right" ] [ text "number of words to test: " ]
                        , div [ class "col-sm-3" ]
                            [ select [ class "form-control", onInput SelectCountOption ]
                                [ option [ selected (model.reviewCount == 10), value "10" ] [ text "10" ]
                                , option [ selected (model.reviewCount == 20), value "20" ] [ text "20" ]
                                , option [ selected (model.reviewCount == 30), value "30" ] [ text "30" ]
                                ]
                            ]
                        ]
                    , div [ class "row form-group" ]
                        [ label [ class "col-sm-6 control-label text-right" ] [ text "Level" ]
                        , div [ class "col-sm-3" ]
                            [ select [ class "form-control", onInput SelectLevelOption ]
                                [ option [ selected (model.reviewLevel == Nothing), value "Any" ] [ text "Any" ]
                                , option [ selected (model.reviewLevel == Just 1), value "1" ] [ text "1" ]
                                , option [ selected (model.reviewLevel == Just 2), value "2" ] [ text "2" ]
                                , option [ selected (model.reviewLevel == Just 3), value "3" ] [ text "3" ]
                                , option [ selected (model.reviewLevel == Just 4), value "4" ] [ text "4" ]
                                , option [ selected (model.reviewLevel == Just 5), value "5" ] [ text "5" ]
                                ]
                            ]
                        ]
                    ]
                , div [ class "card-footer" ]
                    [ button [ class "btn btn-primary", onClick StartReviewClicked ] [ text "Start Now!" ]
                    ]
                ]
            ]
        ]


reviewView : Model -> Html Msg
reviewView model =
    let
        inputFieldDisabled =
            case model.translationState of
                Nothing ->
                    False

                _ ->
                    True
    in
    case model.currentReview of
        Nothing ->
            div [] [ text "finished" ]

        Just review ->
            div [ class "row" ]
                [ div [ class "col-sm-6 offset-sm-3" ]
                    [ h1 [ class "pl-3" ] [ text "Translate" ]
                    , div [ class "card" ]
                        [ h5 [ class "card-header" ] [ titleView review ]
                        , div [ class "card-body" ]
                            [ div [ class "form-group" ]
                                [ label [ for "inputTranslation" ] [ text "Translation" ]
                                , input
                                    [ class "form-control"
                                    , type_ "text"
                                    , id "inputTranslation"
                                    , value model.currentTranslation
                                    , ariaDescribedby "translationHelp"
                                    , required True
                                    , onInput SetReviewTranslation
                                    , onEnter CheckButtonClicked

                                    --, disabled inputFieldDisabled
                                    ]
                                    []
                                , small [ id "translationHelp", class "form-text text-muted" ]
                                    [ text "Translate this german word using a dictionary or an online resource like "
                                    ]
                                ]
                            , stateView model review
                            ]
                        , div [ class "card-footer" ]
                            [ buttonView model
                            ]
                        ]
                    ]
                ]


titleView : Review -> Html Msg
titleView review =
    let
        category =
            case review.word.category of
                Nothing ->
                    ""

                Just wordCategory ->
                    " (" ++ wordCategory ++ ")"
    in
    text (review.translation.translation ++ category)


stateView : Model -> Review -> Html Msg
stateView model review =
    let
        sentence =
            case review.translation.sentence of
                Nothing ->
                    ""

                Just _ ->
                    Maybe.withDefault "" review.translation.sentence
    in
    case model.translationState of
        Nothing ->
            text ""

        Just True ->
            div []
                [ div []
                    [ text "Correct!!" ]
                , div [ class "text-muted" ]
                    [ text sentence ]
                ]

        Just False ->
            div []
                [ div []
                    [ text "You are wrong! The correct word is: "
                    , text (fullWord review.word.article review.word.german)
                    ]
                , div [ class "text-muted" ]
                    [ text sentence ]
                ]


buttonView : Model -> Html Msg
buttonView model =
    case model.translationState of
        Nothing ->
            button
                [ class "btn btn-primary"
                , onClick CheckButtonClicked
                ]
                [ text "Check" ]

        Just state ->
            button
                [ class "btn btn-primary"
                , id "nextButton"
                , onClick NextButtonClicked
                ]
                [ text "Next" ]


resultsView : List TranslationResult -> Html Msg
resultsView results =
    div []
        [ summaryView results
        , table [ class "table table-striped" ]
            [ thead [ class "thead-dark" ]
                [ tr []
                    [ th [ scope "col" ] [ text "GERMAN" ]
                    , th [ scope "col" ] [ text "TRANSLATION" ]
                    , th [ scope "col" ] [ text "REVIEW" ]
                    , th [ scope "col", class "text-center" ] [ text "RESULT" ]
                    ]
                ]
            , tbody [] (List.map resultRow results)
            ]
        ]


summaryView : List TranslationResult -> Html Msg
summaryView results =
    let
        total =
            List.length results

        correct =
            ListExtra.count (\r -> r.correct) results
    in
    h2 [] [ text ("Result: " ++ String.fromInt correct ++ " / " ++ String.fromInt total) ]


resultRow : TranslationResult -> Html Msg
resultRow result =
    tr []
        [ td [] [ text result.german ]
        , td [] [ text result.translation ]
        , td [] [ text result.reviewTranslation ]
        , td [ class "text-center" ] [ correctView result.correct ]
        ]


correctView : Bool -> Html Msg
correctView correct =
    case correct of
        True ->
            text (String.fromChar tickMark)

        False ->
            text (String.fromChar crossChar)


tickMark : Char
tickMark =
    '✓'


crossChar : Char
crossChar =
    '✕'
