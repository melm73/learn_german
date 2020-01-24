module Page.Translation exposing (Model, Msg, init, update, view)

import Functions exposing (fullWord)
import Html exposing (Html, a, button, div, form, h1, h5, input, label, small, strong, text)
import Html.Attributes exposing (checked, class, classList, disabled, for, href, id, required, target, type_, value)
import Html.Attributes.Aria exposing (ariaDescribedby)
import Html.Events exposing (onCheck, onClick, onInput)
import Http
import Json.Decode as Decoder
import Json.Encode as Encoder
import List.Extra as ListExtra
import State exposing (AppState)



---- MODEL


type alias Model =
    { translation : Maybe Translation
    , newTranslation : Maybe Translation
    , word : Maybe State.Word
    , userId : String
    , urls : State.Urls
    }


type alias Translation =
    { id : Maybe String
    , wordId : String
    , translation : String
    , sentence : String
    , known : Bool
    }



-- INIT


init : AppState -> ( Model, Cmd Msg )
init state =
    ( { translation = Nothing
      , newTranslation = Nothing
      , word = ListExtra.find (\w -> w.id == state.currentWordId) state.words
      , userId = state.user.id
      , urls = state.urls
      }
    , getTranslationRequest state
    )


defaultTranslation : Translation
defaultTranslation =
    { id = Nothing
    , wordId = ""
    , translation = ""
    , sentence = ""
    , known = False
    }



-- UPDATE


type Msg
    = SetTranslation String
    | SetSentence String
    | SetKnown Bool
    | SaveTranslation
    | HandleCreateResponse (Result Http.Error String)
    | HandleUpdateResponse (Result Http.Error ())
    | HandleTranslationResponse (Result Http.Error (List Translation))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetTranslation translation ->
            let
                newTranslation =
                    case model.newTranslation of
                        Nothing ->
                            Just { defaultTranslation | translation = translation }

                        Just oldTranslation ->
                            Just { oldTranslation | translation = translation }
            in
            ( { model | newTranslation = newTranslation }, Cmd.none )

        SetSentence sentence ->
            let
                newTranslation =
                    case model.newTranslation of
                        Nothing ->
                            Just { defaultTranslation | sentence = sentence }

                        Just oldTranslation ->
                            Just { oldTranslation | sentence = sentence }
            in
            ( { model | newTranslation = newTranslation }, Cmd.none )

        SetKnown known ->
            let
                newTranslation =
                    case model.newTranslation of
                        Nothing ->
                            Just { defaultTranslation | known = known }

                        Just oldTranslation ->
                            Just { oldTranslation | known = known }
            in
            ( { model | newTranslation = newTranslation }, Cmd.none )

        SaveTranslation ->
            let
                request =
                    case ( model.newTranslation, model.word ) of
                        ( Just translation, Just word ) ->
                            case translation.id of
                                Nothing ->
                                    createTranslationRequest model word translation model.urls

                                Just id ->
                                    updateTranslationRequest model translation model.urls

                        ( _, _ ) ->
                            Cmd.none
            in
            ( model, request )

        HandleCreateResponse (Ok id) ->
            let
                newTranslation =
                    case model.newTranslation of
                        Nothing ->
                            Nothing

                        Just translation ->
                            Just { translation | id = Just id }
            in
            ( { model | translation = newTranslation, newTranslation = newTranslation }, Cmd.none )

        HandleCreateResponse (Err _) ->
            ( model, Cmd.none )

        HandleUpdateResponse (Ok _) ->
            ( { model | translation = model.newTranslation }, Cmd.none )

        HandleUpdateResponse (Err _) ->
            ( model, Cmd.none )

        HandleTranslationResponse (Ok translations) ->
            let
                newTranslation =
                    case List.head translations of
                        Nothing ->
                            Just defaultTranslation

                        Just translation ->
                            Just translation
            in
            ( { model | translation = List.head translations, newTranslation = newTranslation }, Cmd.none )

        HandleTranslationResponse (Err _) ->
            ( { model | translation = Nothing, newTranslation = Just defaultTranslation }, Cmd.none )


getTranslationRequest : AppState -> Cmd Msg
getTranslationRequest state =
    Http.request
        { method = "GET"
        , headers = [ Http.header "X-CSRF-Token" state.urls.csrfToken ]
        , url = state.urls.translationsUrl ++ "?word_id=" ++ state.currentWordId
        , body = Http.emptyBody
        , expect = Http.expectJson HandleTranslationResponse (Decoder.list translationDecoder)
        , timeout = Nothing
        , tracker = Nothing
        }


translationDecoder : Decoder.Decoder Translation
translationDecoder =
    Decoder.map5 Translation
        (Decoder.field "id" (Decoder.nullable Decoder.string))
        (Decoder.field "wordId" Decoder.string)
        (Decoder.field "translation" Decoder.string)
        (Decoder.field "sentence" Decoder.string)
        (Decoder.field "known" Decoder.bool)


createTranslationRequest : Model -> State.Word -> Translation -> State.Urls -> Cmd Msg
createTranslationRequest model word translation urls =
    Http.request
        { method = "POST"
        , headers = [ Http.header "X-CSRF-Token" urls.csrfToken ]
        , url = urls.translationsUrl
        , body = Http.jsonBody (postEncoder model { translation | wordId = word.id })
        , expect = Http.expectJson HandleCreateResponse idDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


idDecoder =
    Decoder.field "id" Decoder.string


updateTranslationRequest : Model -> Translation -> State.Urls -> Cmd Msg
updateTranslationRequest model translation urls =
    Http.request
        { method = "PUT"
        , headers = [ Http.header "X-CSRF-Token" urls.csrfToken ]
        , url = urls.translationsUrl ++ "/" ++ Maybe.withDefault "" translation.id
        , body = Http.jsonBody (postEncoder model translation)
        , expect = Http.expectWhatever HandleUpdateResponse
        , timeout = Nothing
        , tracker = Nothing
        }


postEncoder : Model -> Translation -> Encoder.Value
postEncoder model translation =
    Encoder.object
        [ ( "translation", translationEncoder model translation ) ]


translationEncoder : Model -> Translation -> Encoder.Value
translationEncoder model translation =
    Encoder.object
        [ ( "user_id", Encoder.string model.userId )
        , ( "word_id", Encoder.string translation.wordId )
        , ( "translation", Encoder.string translation.translation )
        , ( "sentence", Encoder.string translation.sentence )
        , ( "known", Encoder.bool translation.known )
        ]


nothingChanged : Model -> Bool
nothingChanged model =
    case ( model.translation, model.newTranslation ) of
        ( Just translation, Just newTranslation ) ->
            (translation.translation == newTranslation.translation)
                && (translation.sentence == newTranslation.sentence)
                && (translation.known == newTranslation.known)

        ( _, _ ) ->
            False



---- VIEW


view : Model -> AppState -> Html Msg
view model state =
    case ( model.word, model.newTranslation ) of
        ( Just word, Just newTranslation ) ->
            div [ class "row" ]
                [ div [ class "col-sm-6 offset-sm-3" ]
                    [ h1 [ class "pl-3" ] [ text "Translate" ]
                    , div [ class "card" ]
                        [ h5 [ class "card-header" ] [ text (fullWord word.article word.german) ]
                        , div [ class "card-body" ]
                            [ formView word newTranslation
                            ]
                        , div [ class "card-footer" ]
                            [ button
                                [ classList [ ( "btn btn-primary", True ), ( "disabled", nothingChanged model ) ]
                                , disabled (nothingChanged model)
                                , onClick SaveTranslation
                                ]
                                [ text "Save" ]
                            ]
                        ]
                    ]
                ]

        ( _, _ ) ->
            text "loading"


formView : State.Word -> Translation -> Html Msg
formView word translation =
    form []
        [ div [ class "form-group" ]
            [ label [ for "inputTranslation" ] [ text "Translation" ]
            , input
                [ class "form-control"
                , type_ "text"
                , id "inputTranslation"
                , value translation.translation
                , ariaDescribedby "translationHelp"
                , required True
                , onInput SetTranslation
                ]
                []
            , small [ id "translationHelp", class "form-text text-muted" ]
                [ text "Translate this german word using a dictionary or an online resource like "
                , a [ target "_blank", href ("https://dictionary.cambridge.org/dictionary/german-english/" ++ word.german) ] [ text "the Campbridge Dictionary" ]
                , text "."
                ]
            ]
        , div [ class "form-group" ]
            [ label [ for "inputSentence" ] [ text "Sentence" ]
            , input
                [ class "form-control"
                , type_ "text"
                , id "inputSentence"
                , value translation.sentence
                , ariaDescribedby "sentenceHelp"
                , onInput SetSentence
                ]
                []
            , small [ id "sentenceHelp", class "form-text text-muted" ]
                [ text "Make up a sentence using the word '"
                , strong [] [ text word.german ]
                , text "'."
                ]
            ]
        , div [ class "form-group form-check" ]
            [ input
                [ class "form-check-input"
                , id "checkKnown"
                , type_ "checkbox"
                , checked translation.known
                , ariaDescribedby "knownHelp"
                , onCheck SetKnown
                ]
                []
            , label [ class "form-check-label", for "checkKnown" ] [ text "I know this word well." ]
            , small [ id "knownHelp", class "form-text text-muted" ] [ text "Tick this if you know this word well and you don't want it to appear in reviews." ]
            ]
        ]
