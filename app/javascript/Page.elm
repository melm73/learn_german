module Page exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Page.Layout as Page exposing (ActivePage)
import Page.Profile as ProfilePage
import Page.Progress as ProgressPage
import Url



-- MAIN


main : Program () Model Msg
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


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , page : Page
    }


type Page
    = ProfilePage ProfilePage.Model
    | ProgressPage ProgressPage.Model
    | NotFoundPage


type Route
    = ProgressRoute
    | ProfileRoute


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( Model key url initialPage, Cmd.none )


initialPage : Page
initialPage =
    ProfilePage ProfilePage.init



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | ProfileMsg ProfilePage.Msg
    | ProgressMsg ProgressPage.Msg


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

                        _ ->
                            ( { model | page = NotFoundPage }, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( { model | url = url }
            , Cmd.none
            )

        ProfileMsg _ ->
            ( model, Cmd.none )

        ProgressMsg _ ->
            ( model, Cmd.none )



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
                ProfilePage.view subModel
                    |> Page.layout Page.ProfilePage
                    |> Html.map ProfileMsg

            ProgressPage subModel ->
                ProgressPage.view subModel
                    |> Page.layout Page.ProgressPage
                    |> Html.map ProgressMsg

            NotFoundPage ->
                text "page not found"
        ]
    }
