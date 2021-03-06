module Page.Layout exposing (..)

import Html exposing (Html, a, button, div, footer, img, li, nav, span, text, ul)
import Html.Attributes exposing (attribute, class, classList, href, id, src, type_)
import State exposing (AppState)


type ActivePage
    = ProgressPage
    | ProfilePage
    | ReviewPage
    | TranslationPage


layout : ActivePage -> AppState -> Html msg -> Html msg
layout page state content =
    div [ class "container" ]
        [ viewHeader page state
        , div [] [ content ]
        ]


viewHeader : ActivePage -> AppState -> Html msg
viewHeader activePage state =
    nav [ class "navbar navbar-expand-lg navbar-light bg-light justify-content-between mb-3" ]
        [ div [ class "navbar-brand" ]
            [ img [ src "/favicon.ico" ] []
            , span [ class "pl-2" ] [ text "Learn German" ]
            ]
        , button
            [ class "navbar-toggler"
            , type_ "button"
            , attribute "data-toggle" "collapse"
            , attribute "data-target" "#navbarSupportedContent"
            , attribute "aria-controls" "navbarSupportedContent"
            , attribute "aria-expanded" "false"
            , attribute "aria-label" "Toggle navigation"
            ]
            [ span [ class "navbar-toggler-icon" ] [] ]
        , div [ class "collapse navbar-collapse", id "navbarSupportedContent" ]
            [ ul [ class "navbar-nav mr-auto text-right" ]
                [ li [ classList [ ( "nav-item", True ), ( "active", activePage == ProgressPage ) ] ]
                    [ a [ class "nav-link", href "/progress" ] [ text "Progress" ] ]
                , li [ classList [ ( "nav-item", True ), ( "active", activePage == ReviewPage ) ] ]
                    [ a [ class "nav-link", href "/review" ] [ text "Review" ] ]
                ]
            , ul [ class "navbar-nav text-right" ]
                [ li [ class "nav-item dropdown" ]
                    [ a
                        [ class "nav-link dropdown-toggle"
                        , href "#"
                        , id "navbarDropdownMenuLink"
                        , attribute "data-toggle" "dropdown"
                        , attribute "aria-haspopup" "true"
                        , attribute "aria-expanded" "false"
                        ]
                        [ text state.user.name ]
                    , div [ class "dropdown-menu dropdown-menu-right", attribute "aria-labelledby" "#navbarDropdownMenuLink" ]
                        [ a [ class "dropdown-item text-right", href "/logout" ] [ text "logout" ]
                        , a [ class "dropdown-item text-right", href "/profile" ] [ text "my profile" ]
                        ]
                    ]
                ]
            ]
        ]
