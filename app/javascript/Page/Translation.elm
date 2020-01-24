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


type
    Msg
    --= SetTranslation String
    --| SetSentence String
    --| SetKnown Bool
    --| SaveTranslation
    --| HandleCreateResponse (Result Http.Error String)
    --| HandleUpdateResponse (Result Http.Error ())
    = HandleTranslationResponse (Result Http.Error (List Translation))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        --SetTranslation translation ->
        --    let
        --        oldTranslation =
        --            model.newTranslation
        --        newTranslation =
        --            { oldTranslation | translation = translation }
        --    in
        --    ( { model | newTranslation = newTranslation }, Cmd.none )
        --SetSentence sentence ->
        --    let
        --        oldTranslation =
        --            model.newTranslation
        --        newTranslation =
        --            { oldTranslation | sentence = sentence }
        --    in
        --    ( { model | newTranslation = newTranslation }, Cmd.none )
        --SetKnown known ->
        --    let
        --        oldTranslation =
        --            model.newTranslation
        --        newTranslation =
        --            { oldTranslation | known = known }
        --    in
        --    ( { model | newTranslation = newTranslation }, Cmd.none )
        --SaveTranslation ->
        --    let
        --        request =
        --            case model.translation.id of
        --                Nothing ->
        --                    createTranslationRequest
        --                Just id ->
        --                    updateTranslationRequest id
        --    in
        --    ( model, request model )
        --HandleCreateResponse (Ok id) ->
        --    let
        --        translation =
        --            model.newTranslation
        --        newTranslation =
        --            { translation | id = Just id }
        --    in
        --    ( { model | translation = newTranslation }, Cmd.none )
        --HandleCreateResponse (Err _) ->
        --    ( model, Cmd.none )
        --HandleUpdateResponse (Ok _) ->
        --    ( { model | translation = model.newTranslation }, Cmd.none )
        --HandleUpdateResponse (Err _) ->
        --    ( model, Cmd.none )
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



--createTranslationRequest : Model -> Cmd Msg
--createTranslationRequest model =
--    Http.request
--        { method = "POST"
--        , headers = [ Http.header "X-CSRF-Token" model.urls.csrfToken ]
--        , url = model.urls.createTranslationUrl
--        , body = Http.jsonBody (postEncoder model)
--        , expect = Http.expectJson HandleCreateResponse idDecoder
--        , timeout = Nothing
--        , tracker = Nothing
--        }
--idDecoder =
--    Decoder.field "id" Decoder.string
--updateTranslationRequest : String -> Model -> Cmd Msg
--updateTranslationRequest id model =
--    Http.request
--        { method = "PUT"
--        , headers = [ Http.header "X-CSRF-Token" model.urls.csrfToken ]
--        , url = model.urls.updateTranslationUrl ++ "/" ++ id
--        , body = Http.jsonBody (postEncoder model)
--        , expect = Http.expectWhatever HandleUpdateResponse
--        , timeout = Nothing
--        , tracker = Nothing
--        }
--postEncoder : Model -> Encoder.Value
--postEncoder model =
--    Encoder.object
--        [ ( "translation", translationEncoder model ) ]
--translationEncoder : Model -> Encoder.Value
--translationEncoder model =
--    Encoder.object
--        [ ( "word_id", Encoder.string model.word.id )
--        , ( "translation", Encoder.string model.newTranslation.translation )
--        , ( "sentence", Encoder.string model.newTranslation.sentence )
--        , ( "known", Encoder.bool model.newTranslation.known )
--        ]
--anythingChanged : Model -> Bool
--anythingChanged model =
--    (model.translation.translation == model.newTranslation.translation)
--        && (model.translation.sentence == model.newTranslation.sentence)
--        && (model.translation.known == model.newTranslation.known)
---- VIEW


view : Model -> AppState -> Html Msg
view model state =
    div [ class "row" ]
        [ div [ class "col-sm-6 offset-sm-3" ]
            [ h1 [ class "pl-3" ] [ text "Translate" ]
            , div [ class "card" ] []

            --[ h5 [ class "card-header" ] [ text (fullWord model.word.article model.word.german) ]
            --, div [ class "card-body" ]
            --    [ formView model
            --    ]
            --, div [ class "card-footer" ]
            --    [ button
            --        [ classList [ ( "btn btn-primary", True ), ( "disabled", anythingChanged model ) ]
            --        , disabled (anythingChanged model)
            --        , onClick SaveTranslation
            --        ]
            --        [ text "Save" ]
            --    ]
            --]
            ]
        ]



--formView : Model -> Html Msg
--formView model =
--    form []
--        [ div [ class "form-group" ]
--            [ label [ for "inputTranslation" ] [ text "Translation" ]
--            , input
--                [ class "form-control"
--                , type_ "text"
--                , id "inputTranslation"
--                , value model.newTranslation.translation
--                , ariaDescribedby "translationHelp"
--                , required True
--                , onInput SetTranslation
--                ]
--                []
--            , small [ id "translationHelp", class "form-text text-muted" ]
--                [ text "Translate this german word using a dictionary or an online resource like "
--                , a [ target "_blank", href ("https://dictionary.cambridge.org/dictionary/german-english/" ++ model.word.german) ] [ text "the Campbridge Dictionary" ]
--                , text "."
--                ]
--            ]
--        , div [ class "form-group" ]
--            [ label [ for "inputSentence" ] [ text "Sentence" ]
--            , input
--                [ class "form-control"
--                , type_ "text"
--                , id "inputSentence"
--                , value model.newTranslation.sentence
--                , ariaDescribedby "sentenceHelp"
--                , onInput SetSentence
--                ]
--                []
--            , small [ id "sentenceHelp", class "form-text text-muted" ]
--                [ text "Make up a sentence using the word '"
--                , strong [] [ text model.word.german ]
--                , text "'."
--                ]
--            ]
--        , div [ class "form-group form-check" ]
--            [ input
--                [ class "form-check-input"
--                , id "checkKnown"
--                , type_ "checkbox"
--                , checked model.newTranslation.known
--                , ariaDescribedby "knownHelp"
--                , onCheck SetKnown
--                ]
--                []
--            , label [ class "form-check-label", for "checkKnown" ] [ text "I know this word well." ]
--            , small [ id "knownHelp", class "form-text text-muted" ] [ text "Tick this if you know this word well and you don't want it to appear in reviews." ]
--            ]
--        ]
