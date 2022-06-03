-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Cambiatus.Object.Category exposing (..)

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


categories :
    SelectionSet decodesTo Cambiatus.Object.Category
    -> SelectionSet (Maybe (List decodesTo)) Cambiatus.Object.Category
categories object_ =
    Object.selectionForCompositeField "categories" [] object_ (identity >> Decode.list >> Decode.nullable)


category :
    SelectionSet decodesTo Cambiatus.Object.Category
    -> SelectionSet (Maybe decodesTo) Cambiatus.Object.Category
category object_ =
    Object.selectionForCompositeField "category" [] object_ (identity >> Decode.nullable)


description : SelectionSet String Cambiatus.Object.Category
description =
    Object.selectionForField "String" "description" [] Decode.string


iconUri : SelectionSet (Maybe String) Cambiatus.Object.Category
iconUri =
    Object.selectionForField "(Maybe String)" "iconUri" [] (Decode.string |> Decode.nullable)


id : SelectionSet Int Cambiatus.Object.Category
id =
    Object.selectionForField "Int" "id" [] Decode.int


imageUri : SelectionSet (Maybe String) Cambiatus.Object.Category
imageUri =
    Object.selectionForField "(Maybe String)" "imageUri" [] (Decode.string |> Decode.nullable)


insertedAt : SelectionSet Cambiatus.ScalarCodecs.NaiveDateTime Cambiatus.Object.Category
insertedAt =
    Object.selectionForField "ScalarCodecs.NaiveDateTime" "insertedAt" [] (Cambiatus.ScalarCodecs.codecs |> Cambiatus.Scalar.unwrapCodecs |> .codecNaiveDateTime |> .decoder)


metaDescription : SelectionSet (Maybe String) Cambiatus.Object.Category
metaDescription =
    Object.selectionForField "(Maybe String)" "metaDescription" [] (Decode.string |> Decode.nullable)


metaKeywords : SelectionSet (Maybe String) Cambiatus.Object.Category
metaKeywords =
    Object.selectionForField "(Maybe String)" "metaKeywords" [] (Decode.string |> Decode.nullable)


metaTitle : SelectionSet (Maybe String) Cambiatus.Object.Category
metaTitle =
    Object.selectionForField "(Maybe String)" "metaTitle" [] (Decode.string |> Decode.nullable)


name : SelectionSet String Cambiatus.Object.Category
name =
    Object.selectionForField "String" "name" [] Decode.string


products :
    SelectionSet decodesTo Cambiatus.Object.Product
    -> SelectionSet (Maybe (List decodesTo)) Cambiatus.Object.Category
products object_ =
    Object.selectionForCompositeField "products" [] object_ (identity >> Decode.list >> Decode.nullable)


slug : SelectionSet (Maybe String) Cambiatus.Object.Category
slug =
    Object.selectionForField "(Maybe String)" "slug" [] (Decode.string |> Decode.nullable)


updatedAt : SelectionSet Cambiatus.ScalarCodecs.NaiveDateTime Cambiatus.Object.Category
updatedAt =
    Object.selectionForField "ScalarCodecs.NaiveDateTime" "updatedAt" [] (Cambiatus.ScalarCodecs.codecs |> Cambiatus.Scalar.unwrapCodecs |> .codecNaiveDateTime |> .decoder)
