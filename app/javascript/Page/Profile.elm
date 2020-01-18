module Page.Profile exposing (Model, Msg, init, update, view)

import Html exposing (Html, div, h6, p, text)
import Html.Attributes exposing (class)
import Http
import Json.Decode as Decoder
import State exposing (AppState)



---- MODEL


type alias Model =
    { user : Maybe User
    }


type alias User =
    { name : String
    , email : String
    }



-- INIT


init : AppState -> ( Model, Cmd Msg )
init state =
    ( { user = Nothing }
    , getCurrentUserRequest state
    )



-- UPDATE


type Msg
    = HandleCurrentUserResponse (Result Http.Error User)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        HandleCurrentUserResponse (Ok currentUser) ->
            ( { user = Just currentUser }, Cmd.none )

        HandleCurrentUserResponse (Err _) ->
            ( model, Cmd.none )


getCurrentUserRequest : AppState -> Cmd Msg
getCurrentUserRequest state =
    Http.request
        { method = "GET"
        , headers = [ Http.header "X-CSRF-Token" state.urls.csrfToken ]
        , url = state.urls.currentUserProfileUrl
        , body = Http.emptyBody
        , expect = Http.expectJson HandleCurrentUserResponse currentUserDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


currentUserDecoder : Decoder.Decoder User
currentUserDecoder =
    Decoder.map2 User
        (Decoder.field "name" Decoder.string)
        (Decoder.field "email" Decoder.string)



-- VIEW


view : Model -> Html Msg
view model =
    case model.user of
        Nothing ->
            div [] [ text "loading..." ]

        Just currentUser ->
            div [ class "card w-50 center" ]
                [ div [ class "card-header" ] [ text "Profile" ]
                , div [ class "card-body" ]
                    [ h6 [] [ text "Name" ]
                    , p [ class "text-muted" ] [ text currentUser.name ]
                    , h6 [] [ text "Email" ]
                    , p [ class "text-muted" ] [ text currentUser.email ]
                    ]
                ]
