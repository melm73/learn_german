module ProgressPieChart exposing (view)

import Array exposing (Array)
import Color exposing (Color)
import Path
import Shape exposing (Arc, defaultPieConfig)
import TypedSvg exposing (g, svg, text_)
import TypedSvg.Attributes exposing (color, dy, fill, fontSize, stroke, textAnchor, transform, viewBox)
import TypedSvg.Core exposing (Svg, text)
import TypedSvg.Types exposing (AnchorAlignment(..), Fill(..), Transform(..), em)


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


learntText : List Float -> Svg msg
learntText data =
    let
        percentage =
            String.fromInt (round (Maybe.withDefault 0 (List.head data)))
    in
    text_
        [ transform [ Translate (width / 2) (height / 2) ]
        , dy (em 0)
        , textAnchor AnchorMiddle
        , fontSize (em 4)
        , fill (Fill Color.purple)
        ]
        [ text (percentage ++ "% learnt")
        ]


translatedText : List Float -> Svg msg
translatedText data =
    let
        learntCount =
            Maybe.withDefault 0 (List.head data)

        translatedCount =
            Maybe.withDefault 0 (List.head (Maybe.withDefault [] (List.tail data)))

        percentage =
            String.fromInt (round (learntCount + translatedCount))
    in
    text_
        [ transform [ Translate (width / 2) (height / 2) ]
        , dy (em 2)
        , textAnchor AnchorMiddle
        , fontSize (em 2)
        , fill (Fill Color.lightPurple)
        ]
        [ text (percentage ++ "% translated")
        ]


view : List Float -> Svg msg
view data =
    let
        pieData =
            data |> Shape.pie { defaultPieConfig | sortingFn = mySortingFn, cornerRadius = 8, outerRadius = radius, padAngle = 0.03 }
    in
    svg [ viewBox 0 0 width height ]
        [ annular pieData
        , learntText data
        , translatedText data
        ]
