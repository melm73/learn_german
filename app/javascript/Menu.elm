module Menu exposing (..)

import Browser
import Browser.Navigation exposing (load)
import Html exposing (Html, a, button, div, h1, img, li, nav, span, text, ul)
import Html.Attributes exposing (attribute, class, href, id, src, type_)
import Html.Events exposing (onClick)
import Http exposing (request)
import Json.Decode as Decoder
import Json.Encode as Encode



-- MODEL


type alias Model =
    { user : User
    , urls : Urls
    }


type alias User =
    { name : String
    }


type alias Urls =
    { logoutUrl : String
    , csrfToken : String
    }



-- INIT


init : Model -> ( Model, Cmd Msg )
init model =
    ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    nav [ class "navbar navbar-expand-lg navbar-light bg-light justify-content-between mb-3" ]
        [ img [ class "navbar-brand", src "/favicon.ico" ] []
        , button
            [ class "navbar-toggler"
            , type_ "button"
            , attribute "data-toggle" "collapse"
            , attribute "data-target" "#navbarSupportedContent"
            , attribute "aria-controls" "navbarSupportedContent"
            , attribute "aria-expanded" "false"
            , attribute "aria-label" "Toggle navigation"
            ]
            [ span [ class "navbar-toggler-icon" ] [] ]
        , div [ class "collapse navbar-collapse", id "navbarSupportedContent" ]
            [ ul [ class "navbar-nav mr-auto" ]
                [ li [ class "nav-item active" ] [ a [ class "nav-link", href "" ] [ text "Home" ] ]
                , li [ class "nav-item active" ] [ a [ class "nav-link", href "" ] [ text "Progress" ] ]
                , li [ class "nav-item" ] [ a [ class "nav-link", href "" ] [ text "Review" ] ]
                ]
            , ul [ class "navbar-nav" ]
                [ li [ class "nav-item dropdown" ]
                    [ a
                        [ class "nav-link dropdown-toggle"
                        , href "#"
                        , id "navbarDropdownMenuLink"
                        , attribute "data-toggle" "dropdown"
                        , attribute "aria-haspopup" "true"
                        , attribute "aria-expanded" "false"
                        ]
                        [ text model.user.name ]
                    , div [ class "dropdown-menu dropdown-menu-right", attribute "aria-labelledby" "#navbarDropdownMenuLink" ]
                        [ button [ class "dropdown-item", onClick Logout ] [ text "logout" ]
                        ]
                    ]
                ]
            ]
        ]


type Msg
    = Logout
    | HandleResponse (Result Http.Error String)



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Logout ->
            ( model, logout model )

        HandleResponse (Ok redirectUrl) ->
            ( model, load redirectUrl )

        HandleResponse (Err _) ->
            ( model, load "" )


logout : Model -> Cmd Msg
logout model =
    Http.request
        { method = "DELETE"
        , headers = [ Http.header "X-CSRF-Token" model.urls.csrfToken ]
        , url = model.urls.logoutUrl
        , body = Http.emptyBody
        , expect = Http.expectJson HandleResponse redirectDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


redirectDecoder =
    Decoder.field "redirectTo" Decoder.string



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
