module TranslationPage exposing (..)

import Browser
import Functions exposing (fullWord)
import Html exposing (Html, a, button, div, form, h1, h5, input, label, small, strong, text)
import Html.Attributes exposing (checked, class, classList, disabled, for, href, id, required, target, type_, value)
import Html.Attributes.Aria exposing (ariaDescribedby)
import Html.Events exposing (onCheck, onClick, onInput)
import Http exposing (request)
import Json.Decode as Decode
import Json.Encode as Encode



-- MODEL


type alias Flags =
    { translation : Maybe ApiTranslation
    , word : Word
    , userId : String
    , urls : Urls
    }


type alias Model =
    { translation : Translation
    , newTranslation : Translation
    , word : Word
    , userId : String
    , urls : Urls
    }


type alias ApiTranslation =
    { id : String
    , translation : String
    , sentence : String
    , known : Bool
    }


type alias Translation =
    { id : Maybe String
    , translation : String
    , sentence : String
    , known : Bool
    }


type alias Word =
    { id : String
    , german : String
    , article : Maybe String
    }


type alias Urls =
    { createTranslationUrl : String
    , updateTranslationUrl : String
    , csrfToken : String
    }



-- INIT


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        modelTranslation =
            case flags.translation of
                Nothing ->
                    defaultTranslation

                Just translation ->
                    { id = Just translation.id
                    , translation = translation.translation
                    , sentence = translation.sentence
                    , known = translation.known
                    }
    in
    ( { translation = modelTranslation
      , newTranslation = modelTranslation
      , word = flags.word
      , userId = flags.userId
      , urls = flags.urls
      }
    , Cmd.none
    )


defaultTranslation : Translation
defaultTranslation =
    { id = Nothing
    , translation = ""
    , sentence = ""
    , known = False
    }



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "row" ]
        [ div [ class "col-sm-6 offset-sm-3" ]
            [ h1 [] [ text "Translate" ]
            , div [ class "card" ]
                [ h5 [ class "card-header" ] [ text (fullWord model.word.article model.word.german) ]
                , div [ class "card-body" ]
                    [ formView model
                    ]
                , div [ class "card-footer" ]
                    [ button
                        [ classList [ ( "btn btn-primary", True ), ( "disabled", anythingChanged model ) ]
                        , disabled (anythingChanged model)
                        , onClick SaveTranslation
                        ]
                        [ text "Save" ]
                    ]
                ]
            ]
        ]


formView : Model -> Html Msg
formView model =
    form []
        [ div [ class "form-group" ]
            [ label [ for "inputTranslation" ] [ text "Translation" ]
            , input
                [ class "form-control"
                , type_ "text"
                , id "inputTranslation"
                , value model.newTranslation.translation
                , ariaDescribedby "translationHelp"
                , required True
                , onInput SetTranslation
                ]
                []
            , small [ id "translationHelp", class "form-text text-muted" ]
                [ text "Translate this german word using a dictionary or an online resource like "
                , a [ target "_blank", href ("https://dictionary.cambridge.org/dictionary/german-english/" ++ model.word.german) ] [ text "the Campbridge Dictionary" ]
                , text "."
                ]
            ]
        , div [ class "form-group" ]
            [ label [ for "inputSentence" ] [ text "Sentence" ]
            , input
                [ class "form-control"
                , type_ "text"
                , id "inputSentence"
                , value model.newTranslation.sentence
                , ariaDescribedby "sentenceHelp"
                , onInput SetSentence
                ]
                []
            , small [ id "sentenceHelp", class "form-text text-muted" ]
                [ text "Make up a sentence using the word '"
                , strong [] [ text model.word.german ]
                , text "'."
                ]
            ]
        , div [ class "form-group form-check" ]
            [ input
                [ class "form-check-input"
                , id "checkKnown"
                , type_ "checkbox"
                , checked model.newTranslation.known
                , ariaDescribedby "knownHelp"
                , onCheck SetKnown
                ]
                []
            , label [ class "form-check-label", for "checkKnown" ] [ text "I know this word well." ]
            , small [ id "knownHelp", class "form-text text-muted" ] [ text "Tick this if you know this word well and you don't want it to appear in reviews." ]
            ]
        ]



-- MESSAGE


type Msg
    = SetTranslation String
    | SetSentence String
    | SetKnown Bool
    | SaveTranslation
    | HandleCreateResponse (Result Http.Error String)
    | HandleUpdateResponse (Result Http.Error ())



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        SetTranslation translation ->
            let
                oldTranslation =
                    model.newTranslation

                newTranslation =
                    { oldTranslation | translation = translation }
            in
            ( { model | newTranslation = newTranslation }, Cmd.none )

        SetSentence sentence ->
            let
                oldTranslation =
                    model.newTranslation

                newTranslation =
                    { oldTranslation | sentence = sentence }
            in
            ( { model | newTranslation = newTranslation }, Cmd.none )

        SetKnown known ->
            let
                oldTranslation =
                    model.newTranslation

                newTranslation =
                    { oldTranslation | known = known }
            in
            ( { model | newTranslation = newTranslation }, Cmd.none )

        SaveTranslation ->
            let
                request =
                    case model.translation.id of
                        Nothing ->
                            createTranslation

                        Just id ->
                            updateTranslation id
            in
            ( model, request model )

        HandleCreateResponse (Ok id) ->
            let
                translation =
                    model.newTranslation

                newTranslation =
                    { translation | id = Just id }
            in
            ( { model | translation = newTranslation }, Cmd.none )

        HandleCreateResponse (Err _) ->
            ( model, Cmd.none )

        HandleUpdateResponse (Ok _) ->
            ( { model | translation = model.newTranslation }, Cmd.none )

        HandleUpdateResponse (Err _) ->
            ( model, Cmd.none )


createTranslation : Model -> Cmd Msg
createTranslation model =
    Http.request
        { method = "POST"
        , headers = [ Http.header "X-CSRF-Token" model.urls.csrfToken ]
        , url = model.urls.createTranslationUrl
        , body = Http.jsonBody (postEncoder model)
        , expect = Http.expectJson HandleCreateResponse idDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


idDecoder =
    Decode.field "id" Decode.string


updateTranslation : String -> Model -> Cmd Msg
updateTranslation id model =
    Http.request
        { method = "PUT"
        , headers = [ Http.header "X-CSRF-Token" model.urls.csrfToken ]
        , url = model.urls.updateTranslationUrl ++ "/" ++ id
        , body = Http.jsonBody (postEncoder model)
        , expect = Http.expectWhatever HandleUpdateResponse
        , timeout = Nothing
        , tracker = Nothing
        }


postEncoder : Model -> Encode.Value
postEncoder model =
    Encode.object
        [ ( "translation", translationEncoder model ) ]


translationEncoder : Model -> Encode.Value
translationEncoder model =
    Encode.object
        [ ( "user_id", Encode.string model.userId )
        , ( "word_id", Encode.string model.word.id )
        , ( "translation", Encode.string model.newTranslation.translation )
        , ( "sentence", Encode.string model.newTranslation.sentence )
        , ( "known", Encode.bool model.newTranslation.known )
        ]


anythingChanged : Model -> Bool
anythingChanged model =
    (model.translation.translation == model.newTranslation.translation)
        && (model.translation.sentence == model.newTranslation.sentence)
        && (model.translation.known == model.newTranslation.known)



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
