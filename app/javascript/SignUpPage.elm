module Main exposing (..)

import Browser
import Html exposing (Html, button, div, form, h1, input, label, small, text)
import Html.Attributes exposing (class, for, id, required, type_, value)
import Html.Attributes.Aria exposing (ariaDescribedby)
import Html.Events exposing (onClick, onInput)
import Http exposing (request)
import Json.Encode as Encode



-- TYPES


type alias Flags =
    { urls : Urls }


type alias Urls =
    { createUserUrl : String }


type Msg
    = SetName String
    | SetEmail String
    | SetPassword String
    | SetPasswordConfirmation String
    | SubmitForm
    | HandleResponse (Result Http.Error ())


type FormField
    = Name
    | Email
    | Password
    | PasswordConfirmation



-- MODEL


type alias Model =
    { name : String
    , email : String
    , password : String
    , passwordConfirmation : String
    , urls : Urls
    }



-- INIT


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { name = ""
      , email = ""
      , password = ""
      , passwordConfirmation = ""
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
                [ div [ class "card-header" ] [ text "Sign Up" ]
                , div [ class "card-body" ]
                    [ form []
                        [ div [ class "form-group" ]
                            [ label [ for "inputName" ] [ text "Name" ]
                            , input [ type_ "text", class "form-control", id "inputName", value model.name, required True, onInput SetName ] []
                            ]
                        , div [ class "form-group" ]
                            [ label [ for "inputEmail" ] [ text "Email" ]
                            , input [ type_ "text", class "form-control", id "inputEmail", value model.email, required True, onInput SetEmail ] []
                            ]
                        , div [ class "form-group" ]
                            [ label [ for "inputPassword" ] [ text "Password" ]
                            , input [ type_ "password", class "form-control", id "inputPassword", value model.password, required True, ariaDescribedby "passwordHelp", onInput SetPassword ] []
                            , small [ id "passwordHelp", class "text-muted" ] [ text "Your password must be at least 6 characters long" ]
                            ]
                        , div [ class "form-group" ]
                            [ label [ for "inputConfirmation" ] [ text "Password confirmation" ]
                            , input [ type_ "password", class "form-control", id "inputConfirmation", value model.passwordConfirmation, required True, onInput SetPasswordConfirmation ] []
                            ]
                        ]
                    ]
                , div [ class "card-footer" ] [ button [ class "btn btn-primary", onClick SubmitForm ] [ text "Create Account" ] ]
                ]
            ]
        ]



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "msg" msg of
        SetName name ->
            ( { model | name = name }, Cmd.none )

        SetEmail email ->
            ( { model | email = email }, Cmd.none )

        SetPassword password ->
            ( { model | password = password }, Cmd.none )

        SetPasswordConfirmation passwordConfirmation ->
            ( { model | passwordConfirmation = passwordConfirmation }, Cmd.none )

        SubmitForm ->
            ( model, postUser model )

        HandleResponse _ ->
            ( model, Cmd.none )


postUser : Model -> Cmd Msg
postUser model =
    Http.request
        { method = "POST"
        , headers = []
        , url = model.urls.createUserUrl
        , body = Http.jsonBody (postEncoder model)
        , expect = Http.expectWhatever HandleResponse
        , timeout = Nothing
        , tracker = Nothing
        }


postEncoder : Model -> Encode.Value
postEncoder model =
    Encode.object
        [ ( "user", userEncoder model ) ]


userEncoder : Model -> Encode.Value
userEncoder model =
    Encode.object
        [ ( "name", Encode.string model.name )
        , ( "email", Encode.string model.email )
        , ( "password", Encode.string model.password )
        ]



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
