module Page.Progress exposing (Model, Msg, init, view)

import Html exposing (..)


type Msg
    = NoOp


type alias Model =
    { pageTitle : String
    , pageBody : String
    }


init : Model
init =
    { pageTitle = "Progress"
    , pageBody = "This is the Progress Page"
    }


view : Model -> Html Msg
view model =
    div []
        [ h2 [] [ text model.pageTitle ]
        , div [] [ text model.pageBody ]
        ]
