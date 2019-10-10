-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Bespiral.Object.Community exposing (..)

import Bespiral.InputObject
import Bespiral.Interface
import Bespiral.Object
import Bespiral.Scalar
import Bespiral.ScalarCodecs
import Bespiral.Union
import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode as Decode


createdAt : SelectionSet Bespiral.ScalarCodecs.DateTime Bespiral.Object.Community
createdAt =
    Object.selectionForField "ScalarCodecs.DateTime" "createdAt" [] (Bespiral.ScalarCodecs.codecs |> Bespiral.Scalar.unwrapCodecs |> .codecDateTime |> .decoder)


createdBlock : SelectionSet Int Bespiral.Object.Community
createdBlock =
    Object.selectionForField "Int" "createdBlock" [] Decode.int


createdEosAccount : SelectionSet String Bespiral.Object.Community
createdEosAccount =
    Object.selectionForField "String" "createdEosAccount" [] Decode.string


createdTx : SelectionSet String Bespiral.Object.Community
createdTx =
    Object.selectionForField "String" "createdTx" [] Decode.string


creator : SelectionSet String Bespiral.Object.Community
creator =
    Object.selectionForField "String" "creator" [] Decode.string


description : SelectionSet String Bespiral.Object.Community
description =
    Object.selectionForField "String" "description" [] Decode.string


invitedReward : SelectionSet Float Bespiral.Object.Community
invitedReward =
    Object.selectionForField "Float" "invitedReward" [] Decode.float


inviterReward : SelectionSet Float Bespiral.Object.Community
inviterReward =
    Object.selectionForField "Float" "inviterReward" [] Decode.float


issuer : SelectionSet (Maybe String) Bespiral.Object.Community
issuer =
    Object.selectionForField "(Maybe String)" "issuer" [] (Decode.string |> Decode.nullable)


logo : SelectionSet String Bespiral.Object.Community
logo =
    Object.selectionForField "String" "logo" [] Decode.string


maxSupply : SelectionSet (Maybe Float) Bespiral.Object.Community
maxSupply =
    Object.selectionForField "(Maybe Float)" "maxSupply" [] (Decode.float |> Decode.nullable)


memberCount : SelectionSet Int Bespiral.Object.Community
memberCount =
    Object.selectionForField "Int" "memberCount" [] Decode.int


members : SelectionSet decodesTo Bespiral.Object.Profile -> SelectionSet (List decodesTo) Bespiral.Object.Community
members object_ =
    Object.selectionForCompositeField "members" [] object_ (identity >> Decode.list)


minBalance : SelectionSet (Maybe Float) Bespiral.Object.Community
minBalance =
    Object.selectionForField "(Maybe Float)" "minBalance" [] (Decode.float |> Decode.nullable)


name : SelectionSet String Bespiral.Object.Community
name =
    Object.selectionForField "String" "name" [] Decode.string


objectives : SelectionSet decodesTo Bespiral.Object.Objective -> SelectionSet (List decodesTo) Bespiral.Object.Community
objectives object_ =
    Object.selectionForCompositeField "objectives" [] object_ (identity >> Decode.list)


supply : SelectionSet (Maybe Float) Bespiral.Object.Community
supply =
    Object.selectionForField "(Maybe Float)" "supply" [] (Decode.float |> Decode.nullable)


symbol : SelectionSet String Bespiral.Object.Community
symbol =
    Object.selectionForField "String" "symbol" [] Decode.string


type alias TransfersOptionalArguments =
    { after : OptionalArgument String
    , before : OptionalArgument String
    , first : OptionalArgument Int
    , last : OptionalArgument Int
    }


transfers : (TransfersOptionalArguments -> TransfersOptionalArguments) -> SelectionSet decodesTo Bespiral.Object.TransferConnection -> SelectionSet (Maybe decodesTo) Bespiral.Object.Community
transfers fillInOptionals object_ =
    let
        filledInOptionals =
            fillInOptionals { after = Absent, before = Absent, first = Absent, last = Absent }

        optionalArgs =
            [ Argument.optional "after" filledInOptionals.after Encode.string, Argument.optional "before" filledInOptionals.before Encode.string, Argument.optional "first" filledInOptionals.first Encode.int, Argument.optional "last" filledInOptionals.last Encode.int ]
                |> List.filterMap identity
    in
    Object.selectionForCompositeField "transfers" optionalArgs object_ (identity >> Decode.nullable)


type_ : SelectionSet (Maybe String) Bespiral.Object.Community
type_ =
    Object.selectionForField "(Maybe String)" "type" [] (Decode.string |> Decode.nullable)
