module View.Overlay exposing (..)

import Config
import Deck exposing (Deck)
import Dict
import Game exposing (Game)
import Game.Area
import Game.Entity
import Html exposing (Attribute, Html)
import Html.Attributes
import Layout
import View


toHtml : { restart : msg, newGamePlus : msg, reachedAfrica : Bool, selectDeck : Deck -> msg, selectableDecks : List Deck, animationToggle : Bool } -> Game -> Maybe ( List (Attribute msg), Html msg )
toHtml args game =
    (if Game.gameWon game then
        ( [ Html.Attributes.style "background-color" "rgba(158,228,147,0.5)" ]
        , (if args.reachedAfrica then
            [ Html.text "\u{1FABA}" |> Layout.el [ Html.Attributes.style "font-size" "80px", Layout.centerContent ]
            , Html.text "You are back home. Well done!" |> Layout.el []
            , Html.text "Restart"
                |> View.viewButton "Restart" (Just args.restart)
                |> Layout.el [ Layout.contentCentered ]
            ]

           else
            [ Html.text "🐘" |> Layout.el [ Html.Attributes.style "font-size" "80px", Layout.centerContent ]
            , Html.text "You reached Africa. You won the game." |> Layout.el []
            , String.fromInt game.birdsKilled
                ++ " birds of your flock died. "
                ++ (if game.birdsKilled == 0 then
                        "Well done!"

                    else
                        "You can do better."
                   )
                |> Html.text
                |> Layout.el []
            , Html.text "Travel back"
                |> View.viewButton "Travel back" (Just args.newGamePlus)
                |> Layout.el [ Layout.contentCentered ]
            ]
          )
            |> Layout.column [ Layout.spacing Config.spacing ]
        )
            |> Just

     else if Game.gameOver game then
        ( [ Html.Attributes.style "background-color" "rgba(100,64,62,0.5)" ]
        , [ Html.text "💀" |> Layout.el [ Html.Attributes.style "font-size" "80px", Layout.centerContent ]
          , Html.text "Your journey ends at Deaths doorstep" |> Layout.el []
          , Html.text (View.viewDistanceTraveled { reachedAfrica = args.reachedAfrica } game)
          , Html.text "Restart"
                |> View.viewButton "Restart" (Just args.restart)
                |> Layout.el [ Layout.contentCentered ]
          ]
            |> Layout.column
                [ Layout.spacing Config.spacing
                , Html.Attributes.style "background-color" "white"
                , Html.Attributes.style "border-radius" "16px"
                , Html.Attributes.style "border" "1px solid rgba(0,0,0,0.2)"
                , Html.Attributes.style "padding" (String.fromFloat Config.spacing ++ "px")
                ]
        )
            |> Just

     else if Dict.isEmpty game.cards then
        ( [ Html.Attributes.style "background-color" "rgba(191,219,247,1)" ]
        , [ Html.text "Where should your flock fly to?"
                |> Layout.heading2 [ Html.Attributes.style "padding" (String.fromFloat (Config.spacing + 2) ++ "px 0") ]
          , args.selectableDecks
                |> List.indexedMap
                    (\i deck ->
                        View.viewCardBack
                            (Layout.asButton
                                { onPress = Just (args.selectDeck deck), label = "Select " ++ Deck.name deck ++ "Deck" }
                            )
                            deck
                            |> View.viewDeck (Deck.cards deck)
                            |> Game.Entity.move ( toFloat i * (Config.cardWidth + Config.spacing), 0 )
                            |> Game.Entity.map (Tuple.pair ("deck_" ++ String.fromInt i))
                    )
                |> (++)
                    [ (\attrs -> Html.text "☁️" |> Layout.el ([ Html.Attributes.style "font-size" "100px" ] ++ attrs))
                        |> Tuple.pair "cloud1"
                        |> Game.Entity.new
                        |> Game.Entity.move
                            ( -150
                            , -200
                                + (if args.animationToggle then
                                    50

                                   else
                                    0
                                  )
                            )
                    , (\attrs -> Html.text "☁️" |> Layout.el ([ Html.Attributes.style "font-size" "100px" ] ++ attrs))
                        |> Tuple.pair "cloud2"
                        |> Game.Entity.new
                        |> Game.Entity.move
                            ( 150 + Config.cardWidth
                            , -100
                                + (if args.animationToggle then
                                    50

                                   else
                                    0
                                  )
                            )
                    , (\attrs -> Html.text "☁️" |> Layout.el ([ Html.Attributes.style "font-size" "100px" ] ++ attrs))
                        |> Tuple.pair "cloud3"
                        |> Game.Entity.new
                        |> Game.Entity.move
                            ( -150
                            , 100
                                + (if args.animationToggle then
                                    0

                                   else
                                    50
                                  )
                            )
                    ]
                |> Game.Area.toHtml
                    [ Html.Attributes.style "height" (String.fromFloat (Config.cardHeight + 100) ++ "px")
                    , Html.Attributes.style "width" (String.fromFloat (Config.cardWidth * 2 + Config.spacing) ++ "px")
                    ]
                |> Layout.el [ Layout.contentCentered ]
          ]
            |> Layout.column [ Layout.spacing Config.spacing ]
        )
            |> Just

     else
        Nothing
    )
        |> Maybe.map
            (\( attrs, content ) ->
                ( [ Html.Attributes.style "width" "100%"
                  , Html.Attributes.style "height" "100%"
                  ]
                , content
                    |> Layout.el
                        (Layout.centered
                            ++ [ Html.Attributes.style "width" "100%"
                               , Html.Attributes.style "height" "100%"
                               , Html.Attributes.style "backdrop-filter" "blur(4px)"
                               , Html.Attributes.style "z-index" "100"
                               , Html.Attributes.style "position" "relative"
                               ]
                            ++ attrs
                        )
                )
            )
