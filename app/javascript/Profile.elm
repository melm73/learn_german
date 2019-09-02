module Profile exposing (..)

import Browser
import Html exposing (Html, div, h5, h6, p, text)
import Html.Attributes exposing (class)



-- MODEL


type alias Model =
    { user : User
    }


type alias User =
    { name : String
    , email : String
    }



-- INIT


init : Model -> ( Model, Cmd Msg )
init model =
    ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "card w-50 center" ]
        [ div [ class "card-header" ] [ text "Profile" ]
        , div [ class "card-body" ]
            [ h6 [] [ text "Name" ]
            , p [ class "text-muted" ] [ text model.user.name ]
            , h6 [] [ text "Email" ]
            , p [ class "text-muted" ] [ text model.user.email ]
            ]
        ]


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


main : Program Model Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
