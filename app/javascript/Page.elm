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
import State exposing (AppState, User)
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
    , state : AppState
    , page : Page
    }


type Page
    = ProfilePage ProfilePage.Model
    | ProgressPage ProgressPage.Model
    | NotFoundPage


type Route
    = ProgressRoute
    | ProfileRoute



-- INIT


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        state =
            { user = flags.user, urls = flags.urls, words = [] }
    in
    ( { key = key
      , url = url
      , state = state
      , page = NotFoundPage
      }
    , getWordsRequest state
    )



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | ProfileMsg ProfilePage.Msg
    | ProgressMsg ProgressPage.Msg
    | HandleLogoutResponse (Result Http.Error String)
    | HandleWordResponse (Result Http.Error (List State.Word))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( LinkClicked urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    case url.path of
                        "/logout" ->
                            ( model, logoutRequest model.state )

                        _ ->
                            ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        ( UrlChanged url, _ ) ->
            changeRouteTo url model

        ( HandleLogoutResponse (Ok redirectUrl), _ ) ->
            ( model, Nav.load redirectUrl )

        ( HandleLogoutResponse (Err _), _ ) ->
            ( model, Cmd.none )

        ( HandleWordResponse (Ok words), _ ) ->
            let
                oldState =
                    model.state

                newState =
                    { oldState | words = words }
            in
            ( { model | state = newState }, Cmd.none )

        ( HandleWordResponse (Err _), _ ) ->
            ( model, Cmd.none )

        ( ProfileMsg subMsg, ProfilePage pageModel ) ->
            let
                ( subModel, subCmd ) =
                    ProfilePage.update subMsg pageModel
            in
            ( { model | page = ProfilePage subModel }, Cmd.map ProfileMsg subCmd )

        ( ProgressMsg _, _ ) ->
            ( model, Cmd.none )

        ( _, _ ) ->
            ( model, Cmd.none )


changeRouteTo : Url.Url -> Model -> ( Model, Cmd Msg )
changeRouteTo url model =
    case url.path of
        "/profile" ->
            let
                ( subModel, subCmd ) =
                    ProfilePage.init model.state
            in
            ( { model | url = url, page = ProfilePage subModel }
            , Cmd.map ProfileMsg subCmd
            )

        _ ->
            ( { model | url = url }
            , Cmd.none
            )


getWordsRequest : AppState -> Cmd Msg
getWordsRequest state =
    Http.request
        { method = "GET"
        , headers = [ Http.header "X-CSRF-Token" state.urls.csrfToken ]
        , url = state.urls.wordsUrl
        , body = Http.emptyBody
        , expect = Http.expectJson HandleWordResponse (Decoder.list wordDecoder)
        , timeout = Nothing
        , tracker = Nothing
        }


wordDecoder : Decoder.Decoder State.Word
wordDecoder =
    Decoder.map6 State.Word
        (Decoder.field "id" Decoder.string)
        (Decoder.field "german" Decoder.string)
        (Decoder.field "article" (Decoder.nullable articleDecoder))
        (Decoder.field "category" Decoder.string)
        (Decoder.field "plural" (Decoder.nullable Decoder.string))
        (Decoder.field "level" (Decoder.nullable Decoder.int))


articleDecoder : Decoder.Decoder State.Article
articleDecoder =
    Decoder.string
        |> Decoder.andThen
            (\str ->
                case str of
                    "der" ->
                        Decoder.succeed State.Der

                    "die" ->
                        Decoder.succeed State.Die

                    "das" ->
                        Decoder.succeed State.Das

                    somethingElse ->
                        Decoder.fail <| "Unknown article: " ++ somethingElse
            )


logoutRequest : AppState -> Cmd Msg
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
                ProfilePage.view subModel
                    |> Page.layout Page.ProfilePage model.state
                    |> Html.map ProfileMsg

            ProgressPage subModel ->
                ProgressPage.view subModel model.state
                    |> Page.layout Page.ProgressPage model.state
                    |> Html.map ProgressMsg

            NotFoundPage ->
                text "page not found"
                    |> Page.layout Page.ProgressPage model.state
        ]
    }
