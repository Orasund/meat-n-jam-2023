module Game exposing (..)

import Action exposing (Action(..))
import Card exposing (Card, CardId)
import Config
import Deck exposing (Deck)
import Dict exposing (Dict)
import Event exposing (Event)
import Random exposing (Generator)


type alias Game =
    { cards : Dict CardId Card
    , deck : List CardId
    , deckType : Deck
    , ground : Maybe CardId
    , food : Int
    , flockSize : Int
    , remainingRests : Int
    , birdsKilled : Int
    }


initialDeck : List Card
initialDeck =
    [ List.repeat 2 Card.Wind
    , List.repeat 4 Card.Food
    , List.repeat 4 Card.Predator
    ]
        |> List.concat


init : Game
init =
    { cards = Dict.empty
    , deck = []
    , deckType = Deck.Beach
    , ground = Nothing
    , food = 3
    , flockSize = 3
    , remainingRests = Config.totalDistance
    , birdsKilled = 0
    }


gameOver : Game -> Bool
gameOver game =
    game.food < 0 || game.flockSize <= 0


gameWon : Game -> Bool
gameWon game =
    game.remainingRests <= 0


shuffle : List a -> Generator (List a)
shuffle list =
    Random.list (List.length list) (Random.float 0 1)
        |> Random.map
            (\randomList ->
                randomList
                    |> List.map2 Tuple.pair list
                    |> List.sortBy Tuple.second
                    |> List.map Tuple.first
            )


drawCard : Game -> Game
drawCard game =
    case game.deck of
        head :: tail ->
            { game | ground = Just head, deck = tail }

        [] ->
            game


applyAction : Action -> Game -> Generator ( Game, List Event )
applyAction action game =
    case action of
        AddFoodAndThen amount action2 ->
            { game | food = game.food + amount }
                |> applyAction action2

        DrawCard ->
            ( drawCard game, [ Event.PlaySound Event.Draw ] ) |> Random.constant

        AddBirdAndThen action2 ->
            { game | flockSize = game.flockSize + 1 }
                |> applyAction action2
                |> Random.map (Tuple.mapSecond ((::) (Event.PlaySound Event.AddBird)))

        LooseBirdAndThen action2 ->
            { game | flockSize = game.flockSize - 1, birdsKilled = game.birdsKilled + 1 }
                |> applyAction action2
                |> Random.map
                    (\( g, l ) ->
                        ( g
                        , if gameOver g then
                            Event.PlaySound Event.Loose :: l

                          else
                            l
                        )
                    )

        Shuffle ->
            game.deck
                |> shuffle
                |> Random.map (\deck -> ( { game | deck = deck }, [ Event.PlaySound Event.Shuffle ] ))

        RemoveDeckAndThen action2 ->
            { game
                | deck = []
                , ground = Nothing
                , remainingRests = game.remainingRests - 1
                , cards = Dict.empty
            }
                |> applyAction action2
                |> Random.map
                    (\( g, l ) ->
                        ( g
                        , (if gameWon g then
                            Event.PlaySound Event.Win

                           else
                            Event.PlaySound Event.TakeOff
                          )
                            :: l
                        )
                    )

        ChooseNewDeck ->
            Deck.asList
                |> shuffle
                |> Random.map
                    (\l ->
                        case l of
                            h1 :: h2 :: _ ->
                                [ h1, h2 ]

                            _ ->
                                []
                    )
                |> Random.map
                    (\list ->
                        ( game
                        , [ Event.ChooseDeck list ]
                        )
                    )

        NewDeck deck ->
            Random.constant
                ( { game
                    | deck = List.range 0 (List.length (Deck.cards deck) - 1)
                    , deckType = deck
                    , cards =
                        Deck.cards deck
                            |> List.indexedMap Tuple.pair
                            |> Dict.fromList
                  }
                , []
                )

        DiscardCard ->
            ( { game
                | deck = game.deck ++ (game.ground |> Maybe.map List.singleton |> Maybe.withDefault [])
                , ground = Nothing
              }
            , [ Event.PlaySound Event.Discard ]
            )
                |> Random.constant

        IfEnoughFoodAndThen amount trueAction falseAction ->
            case
                if game.food >= amount then
                    trueAction

                else
                    falseAction
            of
                head :: tail ->
                    applyAction head game
                        |> Random.map (Tuple.mapSecond (\l -> l ++ [ Event.AddActions tail ]))

                [] ->
                    Random.constant ( game, [] )

        FilterDeck fun ->
            ( { game
                | deck =
                    game.deck
                        |> List.filter
                            (\cardId ->
                                game.cards
                                    |> Dict.get cardId
                                    |> Maybe.map fun
                                    |> Maybe.withDefault False
                            )
              }
            , []
            )
                |> Random.constant


getCardsFrom : Game -> List CardId -> List ( CardId, Card )
getCardsFrom game list =
    list
        |> List.filterMap
            (\cardId ->
                game.cards
                    |> Dict.get cardId
                    |> Maybe.map (Tuple.pair cardId)
            )
