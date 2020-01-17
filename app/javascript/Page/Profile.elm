module Page.Profile exposing (Model, Msg, init, view)

import Html exposing (..)


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


view : Model -> Html Msg
view model =
    div []
        [ h2 [] [ text model.pageTitle ]
        , div [] [ text model.pageBody ]
        ]
