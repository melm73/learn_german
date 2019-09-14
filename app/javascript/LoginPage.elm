module LoginPage exposing (..)

import Browser
import Browser.Navigation exposing (load)
import Html exposing (Html, a, button, div, form, h1, input, label, small, text)
import Html.Attributes exposing (class, for, href, id, required, type_, value)
import Html.Attributes.Aria exposing (ariaDescribedby)
import Html.Events exposing (onClick, onInput)
import Http exposing (request)
import Json.Decode as Decoder
import Json.Encode as Encode



-- TYPES


type alias Flags =
    { urls : Urls }


type alias Urls =
    { signUpUrl : String
    , loginUrl : String
    , csrfToken : String
    }


type Msg
    = SetEmail String
    | SetPassword String
    | SubmitForm
    | HandleResponse (Result Http.Error String)


type FormField
    = Email
    | Password



-- MODEL


type alias Model =
    { email : String
    , password : String
    , errorMessage : Maybe String
    , urls : Urls
    }



-- INIT


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { email = ""
      , password = ""
      , errorMessage = Nothing
      , urls = flags.urls
      }
    , Cmd.none
    )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "row" ]
        [ div [ class "col-sm-4 offset-sm-4" ]
            [ div [ class "card" ]
                [ div [ class "card-header" ] [ text "Login" ]
                , div [ class "card-body" ]
                    [ form []
                        [ div [ class "form-group" ]
                            [ label [ for "inputEmail" ] [ text "Email" ]
                            , input [ type_ "text", class "form-control", id "inputEmail", value model.email, required True, onInput SetEmail ] []
                            ]
                        , div [ class "form-group" ]
                            [ label [ for "inputPassword" ] [ text "Password" ]
                            , input [ type_ "password", class "form-control", id "inputPassword", value model.password, required True, onInput SetPassword ] []
                            ]
                        , errorView model
                        ]
                    ]
                , div [ class "card-footer" ]
                    [ button [ class "btn btn-primary", onClick SubmitForm ] [ text "Login" ]
                    , a [ href model.urls.signUpUrl ] [ text "Sign-up now!" ]
                    ]
                ]
            ]
        ]


errorView : Model -> Html Msg
errorView model =
    case model.errorMessage of
        Nothing ->
            text ""

        Just errorMessage ->
            small [ class "text-danger" ] [ text errorMessage ]



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetEmail email ->
            ( { model | email = email }, Cmd.none )

        SetPassword password ->
            ( { model | password = password }, Cmd.none )

        SubmitForm ->
            ( model, login model )

        HandleResponse (Ok redirectUrl) ->
            ( model, load redirectUrl )

        HandleResponse (Err _) ->
            ( { model | errorMessage = Just "Invalid username/password" }, Cmd.none )


login : Model -> Cmd Msg
login model =
    Http.request
        { method = "POST"
        , headers = [ Http.header "X-CSRF-Token" model.urls.csrfToken ]
        , url = model.urls.loginUrl
        , body = Http.jsonBody (loginEncoder model)
        , expect = Http.expectJson HandleResponse redirectDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


loginEncoder : Model -> Encode.Value
loginEncoder model =
    Encode.object
        [ ( "session", sessionEncoder model ) ]


sessionEncoder : Model -> Encode.Value
sessionEncoder model =
    Encode.object
        [ ( "email", Encode.string model.email )
        , ( "password", Encode.string model.password )
        ]


redirectDecoder =
    Decoder.field "redirectTo" Decoder.string



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
