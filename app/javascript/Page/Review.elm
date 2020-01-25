module Page.Review exposing (..)

import Browser.Dom as Dom
import Functions exposing (fullWord)
import Html exposing (Html, button, div, h1, h5, input, label, small, strong, text)
import Html.Attributes exposing (class, for, id, required, type_, value)
import Html.Attributes.Aria exposing (ariaDescribedby)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Http
import Json.Decode as Decoder
import State exposing (AppState)
import Task



---- MODEL


type alias Model =
    { reviewState : ReviewState
    , remainingReviews : List Review
    , currentReview : Maybe Review
    , currentTranslation : String
    , translationState : Maybe Bool
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



-- INIT


init : AppState -> ( Model, Cmd Msg )
init state =
    ( { reviewState = SelectingOptions
      , remainingReviews = []
      , currentReview = Nothing
      , currentTranslation = ""
      , translationState = Nothing
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
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        StartReviewClicked ->
            ( { model | reviewState = FetchingReviews }, getReviewsRequest model )

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
                correct =
                    case model.currentReview of
                        Nothing ->
                            Nothing

                        Just review ->
                            Just (model.currentTranslation == fullWord review.word.article review.word.german)
            in
            ( { model | translationState = correct }, focusOn "nextButton" )

        NextButtonClicked ->
            let
                cmd =
                    case ( model.currentReview, model.translationState ) of
                        ( Nothing, _ ) ->
                            Cmd.none

                        ( Just review, Nothing ) ->
                            Cmd.none

                        ( Just review, Just correct ) ->
                            postReviewRequest model review correct
            in
            ( model, cmd )

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


getReviewsRequest : Model -> Cmd Msg
getReviewsRequest model =
    Http.request
        { method = "GET"
        , headers = [ Http.header "X-CSRF-Token" model.urls.csrfToken ]
        , url = model.urls.reviewsUrl
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
            optionsView

        FetchingReviews ->
            div [] [ text "please wait... fetching" ]

        Reviewing ->
            reviewView model

        Finished ->
            div [] [ text "All done!" ]

        Error ->
            div [] [ text "something went wrong" ]


optionsView : Html Msg
optionsView =
    div [ class "card row" ]
        [ div [ class "card-body col" ]
            [ div []
                [ text "translated words only"
                ]
            , div []
                [ text "maximum number of words to test: "
                , strong [] [ text "10" ]
                ]
            , div []
                [ text "group: "
                , strong [] [ text "All" ]
                ]
            ]
        , div [ class "card-footer" ]
            [ button [ class "btn btn-primary", onClick StartReviewClicked ] [ text "Start Now!" ]
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
    case model.translationState of
        Nothing ->
            text ""

        Just True ->
            text "Correct!!"

        Just False ->
            div []
                [ text "You are wrong! The correct word is: "
                , text (fullWord review.word.article review.word.german)
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
