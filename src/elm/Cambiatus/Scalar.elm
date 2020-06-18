-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Cambiatus.Scalar exposing (Codecs, Date(..), DateTime(..), Id(..), defaultCodecs, defineCodecs, unwrapCodecs, unwrapEncoder)

import Graphql.Codec exposing (Codec)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type Date
    = Date String


type DateTime
    = DateTime String


type Id
    = Id String


defineCodecs :
    { codecDate : Codec valueDate
    , codecDateTime : Codec valueDateTime
    , codecId : Codec valueId
    }
    -> Codecs valueDate valueDateTime valueId
defineCodecs definitions =
    Codecs definitions


unwrapCodecs :
    Codecs valueDate valueDateTime valueId
    ->
        { codecDate : Codec valueDate
        , codecDateTime : Codec valueDateTime
        , codecId : Codec valueId
        }
unwrapCodecs (Codecs unwrappedCodecs) =
    unwrappedCodecs


unwrapEncoder getter (Codecs unwrappedCodecs) =
    (unwrappedCodecs |> getter |> .encoder) >> Graphql.Internal.Encode.fromJson


type Codecs valueDate valueDateTime valueId
    = Codecs (RawCodecs valueDate valueDateTime valueId)


type alias RawCodecs valueDate valueDateTime valueId =
    { codecDate : Codec valueDate
    , codecDateTime : Codec valueDateTime
    , codecId : Codec valueId
    }


defaultCodecs : RawCodecs Date DateTime Id
defaultCodecs =
    { codecDate =
        { encoder = \(Date raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map Date
        }
    , codecDateTime =
        { encoder = \(DateTime raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map DateTime
        }
    , codecId =
        { encoder = \(Id raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map Id
        }
    }
