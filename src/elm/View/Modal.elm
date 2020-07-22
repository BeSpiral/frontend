module View.Modal exposing
    ( Visibility
    , hidden
    , initWith
    , shown
    , toHtml
    , withBody
    , withFooter
    , withHeader
    )

import Html exposing (Html, button, div, h3, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Icons



-- OPTIONS


{-| All possible options for the modal dialog.
-}
type alias Options msg =
    { header : Maybe String
    , body : Maybe (Html msg)
    , footer : Maybe (Html msg)
    , visibility : Visibility
    , closeMsg : msg
    }


{-| We need at least this options to create a base (empty) modal dialog.
-}
type alias RequiredOptions msg =
    { closeMsg : msg
    , visibility : Visibility
    }



-- MODAL


type Modal msg
    = Modal (Options msg)


{-| Returns full config with all required and optional options.
-}
initWith : RequiredOptions msg -> Modal msg
initWith reqOpts =
    Modal
        { header = Nothing
        , body = Nothing
        , footer = Nothing
        , closeMsg = reqOpts.closeMsg
        , visibility = reqOpts.visibility
        }



-- VISIBILITY


type Visibility
    = Hidden
    | Shown


hidden : Visibility
hidden =
    Hidden


shown : Visibility
shown =
    Shown



-- WITH*


withHeader : String -> Modal msg -> Modal msg
withHeader header (Modal cfg) =
    Modal { cfg | header = Just header }


withBody : Html msg -> Modal msg -> Modal msg
withBody body (Modal cfg) =
    Modal { cfg | body = Just body }


withFooter : Html msg -> Modal msg -> Modal msg
withFooter footer (Modal cfg) =
    Modal { cfg | footer = Just footer }



-- VIEW


toHtml : Modal msg -> Html msg
toHtml (Modal cfg) =
    case cfg.visibility of
        Shown ->
            viewModalDetails cfg

        Hidden ->
            text ""


viewModalDetails : Options msg -> Html msg
viewModalDetails cfg =
    let
        header =
            case cfg.header of
                Just h ->
                    h3 [ class "w-full font-medium text-heading text-2xl mb-2" ]
                        [ text h ]

                Nothing ->
                    text ""

        body =
            case cfg.body of
                Just b ->
                    div []
                        [ b ]

                Nothing ->
                    text ""

        footer =
            case cfg.footer of
                Just f ->
                    div [ class "modal-footer" ]
                        [ f ]

                Nothing ->
                    text ""
    in
    div
        [ class "modal container fade-in" ]
        [ div
            [ class "modal-bg"
            , onClick cfg.closeMsg
            ]
            []
        , div
            [ class "modal-content overflow-auto" ]
            [ button
                [ class "absolute top-0 right-0 mx-4 my-4"
                , onClick cfg.closeMsg
                ]
                [ Icons.close "text-gray-400 fill-current"
                ]
            , div [ class "display flex flex-col justify-around h-full" ]
                [ header
                , body
                , footer
                ]
            ]
        ]
