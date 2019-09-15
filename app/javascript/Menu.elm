module Menu exposing (..)

import Browser
import Browser.Navigation exposing (load)
import Html exposing (Html, a, button, div, h1, img, li, nav, span, text, ul)
import Html.Attributes exposing (attribute, class, classList, href, id, src, type_)
import Html.Events exposing (onClick)
import Http exposing (request)
import Json.Decode as Decoder
import Json.Encode as Encode



-- MODEL


type alias Model =
    { user : User
    , currentPage : String
    , urls : Urls
    }


type alias User =
    { name : String
    }


type alias Urls =
    { logoutUrl : String
    , profileUrl : String
    , progressUrl : String
    , csrfToken : String
    }



-- INIT


init : Model -> ( Model, Cmd Msg )
init model =
    ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    let
        progressPage =
            "progress"

        reviewPage =
            "review"
    in
    nav [ class "navbar navbar-expand-lg navbar-light bg-light justify-content-between mb-3" ]
        [ div [ class "navbar-brand" ]
            [ img [ src "/favicon.ico" ] []
            , span [ class "pl-2" ] [ text "Learn German" ]
            ]
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
            [ ul [ class "navbar-nav mr-auto text-right" ]
                [ li [ classList [ ( "nav-item", True ), ( "active", model.currentPage == progressPage ) ] ]
                    [ a [ class "nav-link", href "/progress" ] [ text "Progress" ] ]
                , li [ classList [ ( "nav-item", True ), ( "active", model.currentPage == reviewPage ) ] ]
                    [ a [ class "nav-link", href "/reviews" ] [ text "Review" ] ]
                ]
            , ul [ class "navbar-nav text-right" ]
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
                        [ button [ class "dropdown-item text-right", onClick Logout ] [ text "logout" ]
                        , a [ class "dropdown-item text-right", href "/profile" ] [ text "my profile" ]
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
