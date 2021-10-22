-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Cambiatus.Object.NewsReceipt exposing (..)

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


insertedAt : SelectionSet Cambiatus.ScalarCodecs.NaiveDateTime Cambiatus.Object.NewsReceipt
insertedAt =
    Object.selectionForField "ScalarCodecs.NaiveDateTime" "insertedAt" [] (Cambiatus.ScalarCodecs.codecs |> Cambiatus.Scalar.unwrapCodecs |> .codecNaiveDateTime |> .decoder)


reactions : SelectionSet (List String) Cambiatus.Object.NewsReceipt
reactions =
    Object.selectionForField "(List String)" "reactions" [] (Decode.string |> Decode.list)


updatedAt : SelectionSet Cambiatus.ScalarCodecs.NaiveDateTime Cambiatus.Object.NewsReceipt
updatedAt =
    Object.selectionForField "ScalarCodecs.NaiveDateTime" "updatedAt" [] (Cambiatus.ScalarCodecs.codecs |> Cambiatus.Scalar.unwrapCodecs |> .codecNaiveDateTime |> .decoder)


user :
    SelectionSet decodesTo Cambiatus.Object.User
    -> SelectionSet decodesTo Cambiatus.Object.NewsReceipt
user object_ =
    Object.selectionForCompositeField "user" [] object_ identity
