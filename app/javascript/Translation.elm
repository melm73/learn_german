module TranslationPage exposing (..)

import Browser
import Functions exposing (fullWord)
import Html exposing (Html, a, button, div, form, h1, h5, input, label, small, strong, text)
import Html.Attributes exposing (checked, class, for, href, id, required, target, type_, value)
import Html.Attributes.Aria exposing (ariaDescribedby)



-- MODEL


type alias Flags =
    { translation : Maybe ApiTranslation
    , word : Word
    , urls : Urls
    }


type alias Model =
    { translation : Translation
    , word : Word
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
    { csrfToken : String
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
      , word = flags.word
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
                    [ button [ class "btn btn-primary" ] [ text "Save" ]
                    ]
                ]
            ]
        ]



--      <div className="card-footer">
--        <button disabled={this.props.hasEdits} onClick={this.onSubmit} className="btn btn-primary">Save</button>
--        {this.renderSaving()}
--      </div>


formView : Model -> Html Msg
formView model =
    form []
        [ div [ class "form-group" ]
            [ label [ for "inputTranslation" ] [ text "Translation" ]
            , input
                [ class "form-control"
                , type_ "text"
                , id "inputTranslation"
                , value model.translation.translation
                , ariaDescribedby "translationHelp"
                , required True
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
                , value model.translation.sentence
                , ariaDescribedby "sentenceHelp"
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
                , checked model.translation.known
                , ariaDescribedby "knownHelp"
                ]
                []
            , label [ class "form-check-label", for "checkKnown" ] [ text "I know this word well." ]
            , small [ id "knownHelp", class "form-text text-muted" ] [ text "Tick this if you know this word well and you don't want it to appear in reviews." ]
            ]
        ]



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


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
