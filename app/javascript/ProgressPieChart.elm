module ProgressPieChart exposing (Stats, view)

import Array exposing (Array)
import Color exposing (Color)
import Path
import Shape exposing (Arc, defaultPieConfig)
import TypedSvg exposing (g, svg, text_)
import TypedSvg.Attributes exposing (color, dy, fill, fontSize, stroke, textAnchor, transform, viewBox)
import TypedSvg.Core exposing (Svg, text)
import TypedSvg.Types exposing (AnchorAlignment(..), Fill(..), Transform(..), em)


type alias Stats =
    { percentageLearnt : Float
    , percentageTranslated : Float
    , percentageNotSeen : Float
    , numberOfWords : Int
    }


width : Float
width =
    650


height : Float
height =
    650


cornerRadius : Float
cornerRadius =
    20


colors : Array Color
colors =
    Array.fromList
        [ Color.purple
        , Color.lightPurple
        , Color.white
        ]


radius : Float
radius =
    min width height / 2


mySortingFn : Float -> Float -> Order
mySortingFn a b =
    EQ


annular : List Arc -> Svg msg
annular arc =
    let
        makeSlice index datum =
            Path.element (Shape.arc { datum | innerRadius = radius - 60 })
                [ fill <| Fill <| Maybe.withDefault Color.black <| Array.get index colors
                , stroke Color.lightPurple
                ]
    in
    g [ transform [ Translate radius radius ] ]
        [ g [] <| List.indexedMap makeSlice arc
        ]


learntText : Float -> Svg msg
learntText percentageLearnt =
    text_
        [ transform [ Translate (width / 2) (height / 2) ]
        , dy (em -1)
        , textAnchor AnchorMiddle
        , fontSize (em 4)
        , fill (Fill Color.purple)
        ]
        [ text (String.fromInt (round percentageLearnt) ++ "% learnt")
        ]


translatedText : Float -> Svg msg
translatedText percentageTranslated =
    let
        percentage =
            String.fromInt (round percentageTranslated)
    in
    text_
        [ transform [ Translate (width / 2) (height / 2) ]
        , dy (em 0)
        , textAnchor AnchorMiddle
        , fontSize (em 2)
        , fill (Fill Color.lightPurple)
        ]
        [ text (percentage ++ "% translated")
        ]


totalText : Int -> Svg msg
totalText numberOfWords =
    text_
        [ transform [ Translate (width / 2) (height / 2) ]
        , dy (em 2)
        , textAnchor AnchorMiddle
        , fontSize (em 3)
        , fill (Fill Color.purple)
        ]
        [ text (String.fromInt numberOfWords ++ " words")
        ]


view : Stats -> Svg msg
view stats =
    let
        data =
            [ stats.percentageLearnt, stats.percentageTranslated, stats.percentageNotSeen ]

        pieData =
            [ stats.percentageLearnt, stats.percentageTranslated, stats.percentageNotSeen ]
                |> Shape.pie { defaultPieConfig | sortingFn = mySortingFn, cornerRadius = 8, outerRadius = radius, padAngle = 0.03 }
    in
    svg [ viewBox 0 0 width height ]
        [ annular pieData
        , learntText stats.percentageLearnt
        , translatedText (stats.percentageLearnt + stats.percentageTranslated)
        , totalText stats.numberOfWords
        ]
