-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Cambiatus.Object.ContributionConfig exposing (..)

import Cambiatus.Enum.CurrencyType
import Cambiatus.InputObject
import Cambiatus.Interface
import Cambiatus.Object
import Cambiatus.Scalar
import Cambiatus.ScalarCodecs
import Cambiatus.Union
import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode as Decode


acceptedCurrencies : SelectionSet (List Cambiatus.Enum.CurrencyType.CurrencyType) Cambiatus.Object.ContributionConfig
acceptedCurrencies =
    Object.selectionForField "(List Enum.CurrencyType.CurrencyType)" "acceptedCurrencies" [] (Cambiatus.Enum.CurrencyType.decoder |> Decode.list)


paypalAccount : SelectionSet (Maybe String) Cambiatus.Object.ContributionConfig
paypalAccount =
    Object.selectionForField "(Maybe String)" "paypalAccount" [] (Decode.string |> Decode.nullable)


thankYouDescription : SelectionSet (Maybe String) Cambiatus.Object.ContributionConfig
thankYouDescription =
    Object.selectionForField "(Maybe String)" "thankYouDescription" [] (Decode.string |> Decode.nullable)


thankYouTitle : SelectionSet (Maybe String) Cambiatus.Object.ContributionConfig
thankYouTitle =
    Object.selectionForField "(Maybe String)" "thankYouTitle" [] (Decode.string |> Decode.nullable)
