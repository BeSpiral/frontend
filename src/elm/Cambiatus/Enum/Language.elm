-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Cambiatus.Enum.Language exposing (..)

import Json.Decode as Decode exposing (Decoder)


{-|

  - Amheth - amh-ETH: የኢትዮጵያ አማርኛ ቋንቋ
  - Enus - en-US: US English language
  - Eses - es-ES: idioma español de españa
  - Ptbr - pt-BR: Língua portugesa do Brasil

-}
type Language
    = Amheth
    | Enus
    | Eses
    | Ptbr


list : List Language
list =
    [ Amheth, Enus, Eses, Ptbr ]


decoder : Decoder Language
decoder =
    Decode.string
        |> Decode.andThen
            (\string ->
                case string of
                    "AMHETH" ->
                        Decode.succeed Amheth

                    "ENUS" ->
                        Decode.succeed Enus

                    "ESES" ->
                        Decode.succeed Eses

                    "PTBR" ->
                        Decode.succeed Ptbr

                    _ ->
                        Decode.fail ("Invalid Language type, " ++ string ++ " try re-running the @dillonkearns/elm-graphql CLI ")
            )


{-| Convert from the union type representing the Enum to a string that the GraphQL server will recognize.
-}
toString : Language -> String
toString enum =
    case enum of
        Amheth ->
            "AMHETH"

        Enus ->
            "ENUS"

        Eses ->
            "ESES"

        Ptbr ->
            "PTBR"


{-| Convert from a String representation to an elm representation enum.
This is the inverse of the Enum `toString` function. So you can call `toString` and then convert back `fromString` safely.

    Swapi.Enum.Episode.NewHope
        |> Swapi.Enum.Episode.toString
        |> Swapi.Enum.Episode.fromString
        == Just NewHope

This can be useful for generating Strings to use for <select> menus to check which item was selected.

-}
fromString : String -> Maybe Language
fromString enumString =
    case enumString of
        "AMHETH" ->
            Just Amheth

        "ENUS" ->
            Just Enus

        "ESES" ->
            Just Eses

        "PTBR" ->
            Just Ptbr

        _ ->
            Nothing