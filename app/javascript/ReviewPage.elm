module ReviewPage exposing (..)

import Browser
import Html exposing (Html, button, div, form, strong, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode



-- MODEL


type alias Flags =
    { urls : Urls
    }


type alias Model =
    { state : State
    , reviews : List Review
    , urls : Urls
    }


type alias Urls =
    { getReviewsUrl : String
    , csrfToken : String
    }


type State
    = SelectingOptions
    | FetchingReviews
    | Reviewing
    | Error


type alias Review =
    { translation : Translation
    , word : Word
    }


type alias Translation =
    { id : String
    , userId : String
    , translation : String
    , sentence : Maybe String
    }


type alias Word =
    { id : String
    , german : String
    , article : Maybe String
    }



-- INIT


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { state = SelectingOptions
      , reviews = []
      , urls = flags.urls
      }
    , Cmd.none
    )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ optionsView
        , reviewView model
        ]


optionsView : Html Msg
optionsView =
    div [ class "card row" ]
        [ div [ class "card-body col" ]
            [ div []
                [ text "translated words only"
                ]
            , div []
                [ text "maximum number of words to test: "
                , strong [] [ text "10" ]
                ]
            , div []
                [ text "group: "
                , strong [] [ text "All" ]
                ]
            ]
        , div [ class "card-footer" ]
            [ button [ class "btn btn-primary", onClick StartReviewClicked ] [ text "Start Now!" ]
            ]
        ]


reviewView : Model -> Html Msg
reviewView model =
    case model.state of
        SelectingOptions ->
            div [] [ text "selecting options" ]

        FetchingReviews ->
            div [] [ text "please wait... fetching" ]

        Reviewing ->
            div [] [ text "review started" ]

        Error ->
            div [] [ text "something went wrong" ]



-- MESSAGE


type Msg
    = StartReviewClicked
    | HandleGetReviewsResponse (Result Http.Error (List Review))



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartReviewClicked ->
            ( { model | state = FetchingReviews }, getReviewsRequest model )

        HandleGetReviewsResponse (Ok reviews) ->
            ( { model | state = Reviewing, reviews = reviews }, Cmd.none )

        HandleGetReviewsResponse (Err result) ->
            let
                _ =
                    Debug.log "result" result
            in
            ( { model | state = Error }, Cmd.none )


getReviewsRequest : Model -> Cmd Msg
getReviewsRequest model =
    Http.request
        { method = "GET"
        , headers = [ Http.header "X-CSRF-Token" model.urls.csrfToken ]
        , url = model.urls.getReviewsUrl
        , body = Http.emptyBody
        , expect = Http.expectJson HandleGetReviewsResponse (Decode.list reviewDecoder)
        , timeout = Nothing
        , tracker = Nothing
        }


reviewDecoder : Decode.Decoder Review
reviewDecoder =
    Decode.map2 Review
        (Decode.field "translation" translationDecoder)
        (Decode.field "word" wordDecoder)


translationDecoder : Decode.Decoder Translation
translationDecoder =
    Decode.map4 Translation
        (Decode.field "id" Decode.string)
        (Decode.field "user_id" Decode.string)
        (Decode.field "translation" Decode.string)
        (Decode.field "sentence" (Decode.nullable Decode.string))


wordDecoder : Decode.Decoder Word
wordDecoder =
    Decode.map3 Word
        (Decode.field "id" Decode.string)
        (Decode.field "german" Decode.string)
        (Decode.field "article" (Decode.nullable Decode.string))



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
