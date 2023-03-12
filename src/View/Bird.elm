module View.Bird exposing (..)

import Config
import Dict
import Game exposing (Game)
import Game.Area
import Game.Entity
import Html exposing (Html)
import Html.Attributes
import Layout


toHtml : { animationToggle : Bool, playMusic : msg, birdClicked : Bool } -> Game -> Html msg
toHtml args game =
    List.repeat game.flockSize
        (\attrs ->
            Html.text Config.birdEmoji
                |> Layout.el (Html.Attributes.style "font-size" "64px" :: Layout.asButton { onPress = Just args.playMusic, label = "Play Music" } ++ attrs)
        )
        |> List.indexedMap (\i -> Tuple.pair ("bird_" ++ String.fromInt i))
        |> Game.Area.new ( 0, 0 )
        |> Game.Area.mapZIndex (\_ _ _ -> 2000)
        |> Game.Area.mapPosition
            (\i _ ->
                Tuple.mapBoth
                    ((+)
                        (if game.flockSize <= 1 then
                            200

                         else
                            toFloat i
                                * 300
                                / toFloat (game.flockSize - 1)
                        )
                    )
                    ((+)
                        0
                    )
            )
        |> Game.Area.mapPosition
            (\i _ ->
                if Dict.isEmpty game.cards then
                    Tuple.mapBoth
                        ((+)
                            (if args.animationToggle then
                                0

                             else
                                25
                            )
                        )
                        ((+)
                            ((if args.animationToggle then
                                i + 1

                              else
                                i
                             )
                                |> modBy 2
                                |> toFloat
                                |> (*) 25
                            )
                        )

                else
                    identity
            )
        |> Game.Area.mapRotation
            (\i _ ->
                if Dict.isEmpty game.cards then
                    (+)
                        (((if args.animationToggle then
                            i + 1

                           else
                            i
                          )
                            |> modBy 2
                            |> toFloat
                            |> (*) (pi / 8)
                         )
                            - (pi / 16)
                        )

                else
                    (+)
                        (((if args.animationToggle then
                            i + 1

                           else
                            i
                          )
                            |> modBy 2
                            |> toFloat
                            |> (*) (pi / 2)
                         )
                            + (pi
                                * 3
                                / 2
                              )
                        )
            )
        |> (if not args.birdClicked then
                (::)
                    ((\attrs -> Html.text "Click Me" |> Layout.el attrs)
                        |> Tuple.pair "Click Me"
                        |> Game.Entity.new
                        |> Game.Entity.mapZIndex (\_ -> 2001)
                        |> Game.Entity.mapPosition
                            (Tuple.mapBoth
                                ((+)
                                    (if game.flockSize <= 1 then
                                        200

                                     else
                                        toFloat (game.flockSize - 1)
                                            * 300
                                            / toFloat (game.flockSize - 1)
                                    )
                                )
                                ((+)
                                    0
                                )
                            )
                        |> (\entity ->
                                if args.animationToggle then
                                    entity
                                        |> Game.Entity.move ( 30, 20 )
                                        |> Game.Entity.rotate (pi / 8)

                                else
                                    entity
                                        |> Game.Entity.move ( 0, 20 )
                                        |> Game.Entity.rotate (-pi / 4)
                           )
                    )

            else
                identity
           )
        |> Game.Area.toHtml [ Html.Attributes.style "width" "400px" ]
        |> Layout.el [ Layout.centerContent ]
