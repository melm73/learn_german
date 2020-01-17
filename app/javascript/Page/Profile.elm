module Page.Profile exposing (Model, Msg, init, view)

import Html exposing (..)
import State exposing (State)


type Msg
    = NoOp


type alias Model =
    { pageTitle : String
    , pageBody : String
    }


init : Model
init =
    { pageTitle = "Profile"
    , pageBody = "This is the Profile Page"
    }


view : Model -> State -> Html Msg
view model state =
    div []
        [ h2 [] [ text model.pageTitle ]
        , div [] [ text model.pageBody ]
        ]
