module Page exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
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
    = Profile ProfilePage.Model
    | Progress ProgressPage.Model
    | NotFound


type Route
    = ProgressRoute
    | ProfileRoute


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( Model key url initialPage, Cmd.none )


initialPage : Page
initialPage =
    NotFound



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
                        "/progress" ->
                            ( { model | page = Progress ProgressPage.init }, Nav.pushUrl model.key (Url.toString url) )

                        "/profile" ->
                            ( { model | page = Profile ProfilePage.init }, Nav.pushUrl model.key (Url.toString url) )

                        _ ->
                            ( model, Nav.pushUrl model.key (Url.toString url) )

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
    { title = "URL Interceptor"
    , body =
        [ viewPage model
        , text "The current URL is: "
        , b [] [ text (Url.toString model.url) ]
        , ul []
            [ viewLink "/progress"
            , viewLink "/profile"
            ]
        ]
    }


viewPage : Model -> Html Msg
viewPage model =
    case model.page of
        Profile subModel ->
            ProfilePage.view subModel
                |> Html.map ProfileMsg

        Progress subModel ->
            ProgressPage.view subModel
                |> Html.map ProgressMsg

        NotFound ->
            text "page not found"


viewLink : String -> Html Msg
viewLink path =
    li [] [ a [ href path ] [ text path ] ]
