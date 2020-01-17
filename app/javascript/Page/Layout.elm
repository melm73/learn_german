module Page.Layout exposing (..)

import Html exposing (Html, a, div, footer, hr, nav, text)
import Html.Attributes exposing (href)


type ActivePage
    = Progress
    | Profile



-- Take a page's Html and layout it with a header and footer.


layout : ActivePage -> Html msg -> Html msg
layout page content =
    div []
        [ viewHeader page
        , div [] [ content ]
        , viewFooter
        ]


viewHeader : ActivePage -> Html msg
viewHeader page =
    nav []
        [ div []
            [ a [ href "/" ]
                [ text "Progress" ]
            , text " | "
            , a [ href "/profile" ]
                [ text "Profile" ]
            ]
        , hr [] []
        ]


viewFooter : Html msg
viewFooter =
    footer []
        [ div [] []
        ]
