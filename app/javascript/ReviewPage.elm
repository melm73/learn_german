module ReviewPage exposing (..)

import Browser
import Browser.Dom as Dom
import Functions exposing (fullWord)
import Html exposing (Html, button, div, form, h1, h5, input, label, small, strong, text)
import Html.Attributes exposing (class, classList, disabled, for, id, required, type_, value)
import Html.Attributes.Aria exposing (ariaDescribedby)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Http
import Json.Decode as Decode
import Task



-- MODEL


type alias Flags =
    { urls : Urls
    }


type alias Model =
    { state : State
    , remainingReviews : List Review
    , currentReview : Maybe Review
    , currentTranslation : String
    , translationState : Maybe Bool
    , urls : Urls
    }


type alias Urls =
    { getReviewsUrl : String
    , postReviewUrl : String
    , csrfToken : String
    }


type State
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
    }



-- INIT


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { state = SelectingOptions
      , remainingReviews = []
      , currentReview = Nothing
      , currentTranslation = ""
      , translationState = Nothing
      , urls = flags.urls
      }
    , Cmd.none
    )



-- VIEW


view : Model -> Html Msg
view model =
    case model.state of
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
                        [ h5 [ class "card-header" ] [ text review.translation.translation ]
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



-- MESSAGE


type Msg
    = StartReviewClicked
    | HandleGetReviewsResponse (Result Http.Error (List Review))
    | SetReviewTranslation String
    | CheckButtonClicked
    | NextButtonClicked
    | HandlePostReviewResponse (Result Http.Error ())
    | NoOp



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        StartReviewClicked ->
            ( { model | state = FetchingReviews }, getReviewsRequest model )

        HandleGetReviewsResponse (Ok reviews) ->
            let
                ( first, rest ) =
                    case reviews of
                        [] ->
                            ( Nothing, [] )

                        x :: xs ->
                            ( Just x, xs )
            in
            ( { model | state = Reviewing, currentReview = first, remainingReviews = rest }, focusOn "inputTranslation" )

        HandleGetReviewsResponse (Err result) ->
            ( { model | state = Error }, Cmd.none )

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

                _ =
                    Debug.log "correct" correct
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
                ( first, rest, state ) =
                    case model.remainingReviews of
                        [] ->
                            ( Nothing, [], Finished )

                        x :: xs ->
                            ( Just x, xs, Reviewing )
            in
            ( { model | state = state, currentReview = first, remainingReviews = rest, currentTranslation = "", translationState = Nothing }, focusOn "inputTranslation" )

        HandlePostReviewResponse (Err _) ->
            ( { model | state = Error }, Cmd.none )


getReviewsRequest : Model -> Cmd Msg
getReviewsRequest model =
    Http.request
        { method = "GET"
        , headers = [ Http.header "X-CSRF-Token" model.urls.csrfToken ]
        , url = model.urls.getReviewsUrl
        , body = Http.emptyBody
        , expect = Http.expectJson HandleGetReviewsResponse (Decode.list reviewDecoder)
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
        , url = model.urls.postReviewUrl ++ "?translation_id=" ++ review.translation.id ++ "&correct=" ++ correctString
        , body = Http.emptyBody
        , expect = Http.expectWhatever HandlePostReviewResponse
        , timeout = Nothing
        , tracker = Nothing
        }


reviewDecoder : Decode.Decoder Review
reviewDecoder =
    Decode.map2 Review
        (Decode.field "translation" translationDecoder)
        (Decode.field "word" wordDecoder)


translationDecoder : Decode.Decoder Translation
translationDecoder =
    Decode.map4 Translation
        (Decode.field "id" Decode.string)
        (Decode.field "user_id" Decode.string)
        (Decode.field "translation" Decode.string)
        (Decode.field "sentence" (Decode.nullable Decode.string))


wordDecoder : Decode.Decoder Word
wordDecoder =
    Decode.map3 Word
        (Decode.field "id" Decode.string)
        (Decode.field "german" Decode.string)
        (Decode.field "article" (Decode.nullable Decode.string))


focusOn : String -> Cmd Msg
focusOn target =
    Task.attempt (\_ -> NoOp) (Dom.focus target)



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
