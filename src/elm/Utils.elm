module Utils exposing (decodeDate, decodeTimestamp, posixDateTime, decodeEnterKeyDown)

import Cambiatus.Scalar exposing (DateTime(..))
import Iso8601
import Json.Decode as Decode exposing (Decoder, int, string)
import Time exposing (Posix)


posixDateTime : Maybe DateTime -> Posix
posixDateTime maybedt =
    case maybedt of
        Nothing ->
            Time.millisToPosix 0

        Just (DateTime s) ->
            case Iso8601.toTime s of
                Ok posix ->
                    posix

                Err _ ->
                    Time.millisToPosix 0


decodeDate : Decoder Posix
decodeDate =
    string
        |> Decode.andThen
            (\s ->
                let
                    dateStr =
                        if String.endsWith "Z" s then
                            s

                        else
                            s ++ "Z"
                in
                case Iso8601.toTime dateStr of
                    Ok posix ->
                        Decode.succeed posix

                    Err _ ->
                        Decode.fail "Failed to parse date"
            )


decodeTimestamp : Decode.Decoder Time.Posix
decodeTimestamp =
    Decode.int
        |> Decode.andThen
            (\ms ->
                Decode.succeed <| Time.millisToPosix ms
            )


decodeEnterKeyDown : Decode.Decoder Bool
decodeEnterKeyDown =
    let
        isEnter code =
            case code of
                "Enter" ->
                    True
                _ ->
                    False
    in
    Decode.string
        |> Decode.andThen
           (\cd ->
                Decode.succeed <| isEnter cd
           )
