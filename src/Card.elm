module Card exposing (..)


type alias CardId =
    Int


type Card
    = Wind
    | Food
    | Predator


emoji : Card -> String
emoji card =
    case card of
        Wind ->
            "🌬"

        Food ->
            "\u{1FAB1}"

        Predator ->
            "🦁"


name : Card -> String
name card =
    case card of
        Wind ->
            "Wind"

        Food ->
            "Food"

        Predator ->
            "Predator"


description : Card -> String
description card =
    case card of
        Wind ->
            "Fly to the next location."

        Food ->
            "Add 1 Food"

        Predator ->
            "Remove 1 Bird"
