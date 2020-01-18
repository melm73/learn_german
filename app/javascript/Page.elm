module Page exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as Decoder
import Page.Layout as Page exposing (ActivePage)
import Page.Profile as ProfilePage
import Page.Progress as ProgressPage
import State exposing (State, User)
import Url



-- MAIN


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- MODEL


type alias Flags =
    { user : State.User
    , urls : State.Urls
    }


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , state : State
    , page : Page
    }


type Page
    = ProfilePage ProfilePage.Model
    | ProgressPage ProgressPage.Model
    | NotFoundPage


type Route
    = ProgressRoute
    | ProfileRoute


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( { key = key
      , url = url
      , state = { user = flags.user, urls = flags.urls }
      , page = initialPage
      }
    , Cmd.none
    )


initialPage : Page
initialPage =
    ProfilePage ProfilePage.init



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | ProfileMsg ProfilePage.Msg
    | ProgressMsg ProgressPage.Msg
    | HandleLogoutResponse (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    case url.path of
                        "/" ->
                            ( { model | page = ProgressPage ProgressPage.init }, Nav.pushUrl model.key (Url.toString url) )

                        "/profile" ->
                            ( { model | page = ProfilePage ProfilePage.init }, Nav.pushUrl model.key (Url.toString url) )

                        "/logout" ->
                            ( model, logoutRequest model.state )

                        _ ->
                            ( { model | page = NotFoundPage }, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( { model | url = url }
            , Cmd.none
            )

        HandleLogoutResponse (Ok redirectUrl) ->
            ( model, Nav.load redirectUrl )

        HandleLogoutResponse (Err _) ->
            ( model, Cmd.none )

        ProfileMsg _ ->
            ( model, Cmd.none )

        ProgressMsg _ ->
            ( model, Cmd.none )


logoutRequest : State -> Cmd Msg
logoutRequest state =
    Http.request
        { method = "DELETE"
        , headers = [ Http.header "X-CSRF-Token" state.urls.csrfToken ]
        , url = state.urls.logoutUrl
        , body = Http.emptyBody
        , expect = Http.expectJson HandleLogoutResponse redirectDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


redirectDecoder =
    Decoder.field "redirectTo" Decoder.string



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "Learn German"
    , body =
        [ case model.page of
            ProfilePage subModel ->
                ProfilePage.view subModel model.state
                    |> Page.layout Page.ProfilePage model.state
                    |> Html.map ProfileMsg

            ProgressPage subModel ->
                ProgressPage.view subModel model.state
                    |> Page.layout Page.ProgressPage model.state
                    |> Html.map ProgressMsg

            NotFoundPage ->
                text "page not found"
        ]
    }