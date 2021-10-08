module Eos exposing
    ( Action
    , Asset
    , Authorization
    , EosBool(..)
    , Symbol
    , TableQuery
    , Transaction
    , assetToString
    , boolToEosBool
    , cambiatusSymbol
    , decodeAsset
    , encodeAsset
    , encodeEosBool
    , encodeSymbol
    , encodeTableQuery
    , encodeTransaction
    , eosBoolDecoder
    , eosBoolToBool
    , formatSymbolAmount
    , getSymbolPrecision
    , maxSymbolLength
    , minSymbolLength
    , proposeTransaction
    , symbolDecoder
    , symbolFromString
    , symbolSelectionSet
    , symbolToString
    , symbolToSymbolCodeString
    , updateAuth
    )

import Eos.Account as Account exposing (PermissionName)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, with)
import Iso8601
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import List.Extra
import Time
import Utils



-- TRANSACTION


type alias Transaction =
    List Action


encodeTransaction : Transaction -> Value
encodeTransaction transaction =
    Encode.object
        [ ( "name", Encode.string "eosTransaction" )
        , ( "actions", Encode.list encodeAction transaction )
        ]


proposeTransaction : Account.Name -> String -> List Authorization -> Time.Posix -> Transaction -> Action
proposeTransaction proposer proposalName permissionLevels expiration transaction =
    { accountName = "eosio.msig"
    , name = "propose"
    , authorization =
        { actor = proposer
        , permissionName = Account.samplePermission
        }
    , data = encodeProposal proposer proposalName permissionLevels expiration transaction
    }


encodeProposal : Account.Name -> String -> List Authorization -> Time.Posix -> Transaction -> Value
encodeProposal proposer proposalName permissionLevels expiration transaction =
    Encode.object
        [ ( "proposer", Account.encodeName proposer )
        , ( "proposal_name", Encode.string proposalName )
        , ( "requested", Encode.list encodeAuthorization permissionLevels )
        , ( "trx"
          , Encode.object
                [ ( "expiration"
                  , expiration
                        |> Iso8601.fromTime
                        |> String.toList
                        -- Eos doesn't support milliseconds, so we remove that information
                        |> List.Extra.dropWhileRight (\c -> c /= '.')
                        |> List.Extra.dropWhileRight (not << Char.isDigit)
                        |> String.fromList
                        |> Encode.string
                  )
                , ( "ref_block_num", Encode.int 0 )
                , ( "ref_block_prefix", Encode.int 0 )
                , ( "max_net_usage_words", Encode.int 0 )
                , ( "max_cpu_usage_ms", Encode.int 0 )
                , ( "delay_sec", Encode.int 0 )
                , ( "context_free_actions", encodedEmptyList )
                , ( "actions", Encode.list encodeAction transaction )
                , ( "transaction_extensions", encodedEmptyList )
                ]
          )
        ]


updateAuth :
    Authorization
    -> Account.Name
    -> Int
    -> List { name : Account.Name, weight : Int }
    -> Action
updateAuth authorization targetAccount threshold accounts =
    { accountName = "eosio"
    , name = "updateauth"
    , authorization = authorization
    , data = encodeUpdateAuth targetAccount threshold accounts
    }


encodeUpdateAuth :
    Account.Name
    -> Int
    -> List { name : Account.Name, weight : Int }
    -> Value
encodeUpdateAuth targetAccount threshold accounts =
    let
        encodeAccount account =
            Encode.object
                [ ( "permission"
                  , encodeAuthorization
                        { actor = account.name, permissionName = Account.samplePermission }
                  )
                , ( "weight", Encode.int account.weight )
                ]
    in
    Encode.object
        [ ( "account", Account.encodeName targetAccount )
        , ( "permission", Encode.string "active" )
        , ( "parent", Encode.string "owner" )
        , ( "auth"
          , Encode.object
                [ ( "threshold", Encode.int threshold )
                , ( "keys", encodedEmptyList )
                , ( "accounts", Encode.list encodeAccount accounts )
                ]
          )
        ]


encodedEmptyList : Value
encodedEmptyList =
    Encode.list (\_ -> Encode.null) []



-- ACTION


type alias Action =
    { accountName : String
    , name : String
    , data : Value
    , authorization : Authorization
    }


encodeAction : Action -> Value
encodeAction action =
    Encode.object
        [ ( "account", Encode.string action.accountName )
        , ( "name", Encode.string action.name )
        , ( "authorization", Encode.list encodeAuthorization [ action.authorization ] )
        , ( "data", action.data )
        ]



-- AUTHORIZATION


type alias Authorization =
    { actor : Account.Name
    , permissionName : PermissionName
    }


encodeAuthorization : Authorization -> Value
encodeAuthorization authorization =
    Encode.object
        [ ( "actor", Account.encodeName authorization.actor )
        , ( "permission", Account.encodePermissionName authorization.permissionName )
        ]



-- ASSET


type alias Asset =
    { amount : Float
    , symbol : Symbol
    }


assetToString : Asset -> String
assetToString asset =
    formatSymbolAmount asset.symbol asset.amount
        ++ " "
        ++ symbolToSymbolCodeString asset.symbol


encodeAsset : Asset -> Value
encodeAsset asset =
    Utils.formatFloat asset.amount (getSymbolPrecision asset.symbol) False
        ++ " "
        ++ symbolToSymbolCodeString asset.symbol
        |> Encode.string


decodeAsset : Decoder Asset
decodeAsset =
    Decode.string
        |> Decode.andThen
            (\s ->
                let
                    value =
                        assetStringToFloat s
                            |> Maybe.map Decode.succeed
                            |> Maybe.withDefault (Decode.fail "Fail to decode asset amount")

                    symbol =
                        getSymbolFromAssetString s
                            |> Maybe.map Decode.succeed
                            |> Maybe.withDefault (Decode.fail "Fail to decode asset symbol")
                in
                Decode.map2
                    Asset
                    value
                    symbol
            )


assetStringToFloat : String -> Maybe Float
assetStringToFloat s =
    String.split " " s
        |> List.head
        |> Maybe.andThen String.toFloat


getSymbolFromAssetString : String -> Maybe Symbol
getSymbolFromAssetString s =
    let
        assetArr =
            String.split " " s

        symbol : Maybe String
        symbol =
            assetArr |> List.reverse |> List.head

        precision : Maybe Int
        precision =
            assetArr
                |> List.head
                |> Maybe.andThen (\amount -> Just (String.split "." amount))
                |> Maybe.andThen
                    (\amountArr ->
                        case amountArr of
                            [ _, p ] ->
                                Just (String.length p)

                            _ ->
                                Just 0
                    )
    in
    case ( symbol, precision ) of
        ( Just symbolString, Just p ) ->
            Just (Symbol symbolString p)

        _ ->
            Nothing



-- SYMBOL


{-| Symbol is composed of a 3 to 4 alphanumeric chars long and an integer, used for informing precision
On EOS symbols are displayed like so: `4,EOS` or `0,CMB`


# Definition

@docs Symbol

-}
type Symbol
    = Symbol String Int


getSymbolPrecision : Symbol -> Int
getSymbolPrecision (Symbol _ precision) =
    precision


symbolDecoder : Decoder Symbol
symbolDecoder =
    Decode.string
        |> Decode.andThen
            (\string ->
                if string == "undefined" then
                    Decode.fail "Cannot decode 'undefined' symbol, check Javascript"

                else
                    case symbolFromString string of
                        Just symbol ->
                            Decode.succeed symbol

                        Nothing ->
                            Decode.fail "Cannot decode given symbol"
            )


encodeSymbol : Symbol -> Value
encodeSymbol symbol =
    Encode.string (symbolToString symbol)


symbolToString : Symbol -> String
symbolToString (Symbol symbol precision) =
    [ String.fromInt precision, ",", symbol ]
        |> String.concat


formatSymbolAmount : Symbol -> Float -> String
formatSymbolAmount (Symbol _ precision) amount =
    Utils.formatFloat amount precision True


symbolToSymbolCodeString : Symbol -> String
symbolToSymbolCodeString (Symbol s _) =
    s


minSymbolLength : Int
minSymbolLength =
    3


maxSymbolLength : Int
maxSymbolLength =
    7


symbolFromString : String -> Maybe Symbol
symbolFromString str =
    let
        details =
            String.split "," str |> List.take 2

        maybePrecision : Maybe Int
        maybePrecision =
            List.head details
                |> Maybe.andThen String.toInt

        maybeSymbolCode : Maybe String
        maybeSymbolCode =
            details |> List.reverse |> List.head
    in
    case ( maybeSymbolCode, maybePrecision ) of
        ( Just symbolCode, Just precision ) ->
            if
                String.all Char.isAlpha symbolCode
                    && (String.length symbolCode >= minSymbolLength || String.length symbolCode <= maxSymbolLength)
            then
                Just (Symbol (String.toUpper symbolCode) precision)

            else
                Nothing

        _ ->
            Nothing


symbolSelectionSet : SelectionSet String typeLock -> SelectionSet Symbol typeLock
symbolSelectionSet field =
    SelectionSet.succeed Symbol
        |> with
            (field
                |> SelectionSet.mapOrFail
                    (\s ->
                        case String.split "," s |> List.reverse |> List.head of
                            Just e ->
                                Ok e

                            Nothing ->
                                Err "Can't parse symbol"
                    )
            )
        |> with
            (field
                |> SelectionSet.mapOrFail
                    (\s ->
                        case String.split "," s |> List.head |> Maybe.andThen String.toInt of
                            Just e ->
                                Ok e

                            Nothing ->
                                Err "Can't parse symbol"
                    )
            )


cambiatusSymbol : Symbol
cambiatusSymbol =
    Symbol "CMB" 0


type EosBool
    = EosTrue
    | EosFalse


boolToEosBool : Bool -> EosBool
boolToEosBool b =
    if b then
        EosTrue

    else
        EosFalse


eosBoolToBool : EosBool -> Bool
eosBoolToBool eosBool =
    case eosBool of
        EosTrue ->
            True

        EosFalse ->
            False


encodeEosBool : EosBool -> Value
encodeEosBool eosBool =
    case eosBool of
        EosTrue ->
            Encode.int 1

        EosFalse ->
            Encode.int 0


intToEosBool : Int -> EosBool
intToEosBool v =
    if v == 1 then
        EosTrue

    else
        EosFalse


eosBoolDecoder : Decoder EosBool
eosBoolDecoder =
    Decode.int
        |> Decode.map intToEosBool



-- Table Query


type alias TableQuery =
    { code : String
    , scope : String
    , table : String
    , limit : Int
    }


encodeTableQuery : TableQuery -> Value
encodeTableQuery query =
    Encode.object
        [ ( "code", Encode.string query.code )
        , ( "scope", Encode.string query.scope )
        , ( "table", Encode.string query.table )
        , ( "limit", Encode.int query.limit )
        , ( "json", Encode.bool True )
        ]
