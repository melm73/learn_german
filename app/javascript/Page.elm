module Page exposing (..)

import Browser
import Browser.Navigation as Nav
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as Decoder
import Page.Layout as Page exposing (ActivePage)
import Page.Profile as ProfilePage
import Page.Progress as ProgressPage
import Page.Review as ReviewPage
import Page.Translation as TranslationPage
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
    | TranslationPage TranslationPage.Model
    | ReviewPage ReviewPage.Model
    | NotFoundPage



-- INIT


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        state =
            { user = flags.user
            , urls = flags.urls
            , words = []
            , progresses = Dict.empty
            , filteredWords = []
            , filter = State.initialFilter
            , currentWordId = ""
            , currentWordIndex = Nothing
            }

        initialModel =
            { key = key
            , url = url
            , state = state
            , page = NotFoundPage
            }

        ( model, cmd ) =
            changeRouteTo url initialModel
    in
    ( model, Cmd.batch [ getWordsRequest state, cmd ] )



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | ProfileMsg ProfilePage.Msg
    | ProgressMsg ProgressPage.Msg
    | TranslationMsg TranslationPage.Msg
    | ReviewMsg ReviewPage.Msg
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
            ( { model | state = State.setWords model.state words }, Cmd.none )

        ( HandleWordResponse (Err _), _ ) ->
            ( model, Cmd.none )

        ( ProfileMsg subMsg, ProfilePage pageModel ) ->
            let
                ( subModel, subCmd ) =
                    ProfilePage.update subMsg pageModel
            in
            ( { model | page = ProfilePage subModel }, Cmd.map ProfileMsg subCmd )

        ( ProgressMsg subMsg, ProgressPage pageModel ) ->
            let
                ( subModel, subCmd ) =
                    ProgressPage.update subMsg pageModel
            in
            case subMsg of
                ProgressPage.HandleProgressResponse (Ok progresses) ->
                    ( { model | state = State.setProgresses model.state progresses }, Cmd.map ProgressMsg subCmd )

                ProgressPage.SearchStringChanged searchText ->
                    ( { model | page = ProgressPage subModel, state = State.setFilterSearchText model.state searchText }, Cmd.map ProgressMsg subCmd )

                ProgressPage.ClearSearchText ->
                    ( { model | page = ProgressPage subModel, state = State.clearFilterSearchText model.state }, Cmd.map ProgressMsg subCmd )

                ProgressPage.SelectLearntOption option ->
                    ( { model | page = ProgressPage subModel, state = State.setFilterLearnt model.state option }, Cmd.map ProgressMsg subCmd )

                ProgressPage.SelectTranslatedOption option ->
                    ( { model | page = ProgressPage subModel, state = State.setFilterTranslated model.state option }, Cmd.map ProgressMsg subCmd )

                ProgressPage.SelectLevelOption option ->
                    ( { model | page = ProgressPage subModel, state = State.setFilterLevel model.state option }, Cmd.map ProgressMsg subCmd )

                ProgressPage.PaginationClicked direction ->
                    ( { model | page = ProgressPage subModel, state = State.setPagination model.state direction }, Cmd.map ProgressMsg subCmd )

                _ ->
                    ( { model | page = ProgressPage subModel }, Cmd.map ProgressMsg subCmd )

        ( TranslationMsg subMsg, TranslationPage pageModel ) ->
            let
                ( subModel, subCmd ) =
                    TranslationPage.update subMsg pageModel
            in
            ( { model | page = TranslationPage subModel }, Cmd.map TranslationMsg subCmd )

        ( ReviewMsg subMsg, ReviewPage pageModel ) ->
            let
                ( subModel, subCmd ) =
                    ReviewPage.update subMsg pageModel
            in
            ( { model | page = ReviewPage subModel }, Cmd.map ReviewMsg subCmd )

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

        "/progress" ->
            let
                ( subModel, subCmd ) =
                    ProgressPage.init model.state
            in
            ( { model | url = url, page = ProgressPage subModel }
            , Cmd.map ProgressMsg subCmd
            )

        "/translation" ->
            let
                newState =
                    State.setWord model.state url

                ( subModel, subCmd ) =
                    TranslationPage.init newState
            in
            ( { model | url = url, page = TranslationPage subModel, state = newState }
            , Cmd.map TranslationMsg subCmd
            )

        "/review" ->
            let
                ( subModel, subCmd ) =
                    ReviewPage.init model.state
            in
            ( { model | url = url, page = ReviewPage subModel }
            , Cmd.map ReviewMsg subCmd
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
    Decoder.map7 State.Word
        (Decoder.field "id" Decoder.string)
        (Decoder.field "german" Decoder.string)
        (Decoder.field "article" (Decoder.nullable Decoder.string))
        (Decoder.field "category" Decoder.string)
        (Decoder.field "plural" (Decoder.nullable Decoder.string))
        (Decoder.field "duolingoLevel" (Decoder.nullable Decoder.int))
        (Decoder.field "goetheLevel" (Decoder.nullable Decoder.string))


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

            TranslationPage subModel ->
                TranslationPage.view subModel model.state
                    |> Page.layout Page.TranslationPage model.state
                    |> Html.map TranslationMsg

            ReviewPage subModel ->
                ReviewPage.view subModel model.state
                    |> Page.layout Page.ReviewPage model.state
                    |> Html.map ReviewMsg

            NotFoundPage ->
                text "page not found"
                    |> Page.layout Page.ProgressPage model.state
        ]
    }
