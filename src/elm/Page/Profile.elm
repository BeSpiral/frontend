module Page.Profile exposing (Model, Msg, init, jsAddressToMsg, msgToString, update, view)

import Api.Graphql
import Graphql.Http
import Html exposing (Html, button, div, input, label, p, span, text)
import Html.Attributes exposing (checked, class, for, id, name, type_)
import Html.Events exposing (onClick, stopPropagationOn)
import Http
import I18Next exposing (Translations, t)
import Icons
import Json.Decode as Decode exposing (Value)
import Json.Encode as Encode
import Page
import Page.PublicProfile as PublicProfile
import Profile exposing (Profile)
import PushSubscription exposing (PushSubscription)
import Session.LoggedIn as LoggedIn exposing (External(..), FeedbackStatus(..))
import Session.Shared exposing (Shared)
import Task
import UpdateResult as UR
import View.Pin as Pin



-- INIT


init : LoggedIn.Model -> ( Model, Cmd Msg )
init loggedIn =
    let
        profileQuery =
            Api.Graphql.query loggedIn.shared
                (Profile.query loggedIn.accountName)
                CompletedProfileLoad
    in
    ( initModel loggedIn
    , Cmd.batch
        [ profileQuery
        , Task.succeed CheckPushPref |> Task.perform identity
        ]
    )



-- MODEL


type alias Model =
    { status : Status
    , pinModal : ModalStatus
    , oldPin : Maybe String
    , newPin : Maybe String
    , isNewPinVisible : Bool
    , newPinErrorMsg : Maybe String
    , pushNotifications : Bool
    }


initModel : LoggedIn.Model -> Model
initModel _ =
    { status = Loading
    , pinModal = Hidden
    , oldPin = Nothing
    , newPin = Nothing
    , isNewPinVisible = True
    , newPinErrorMsg = Nothing
    , pushNotifications = False
    }


type Status
    = Loading
    | LoadingFailed (Graphql.Http.Error (Maybe Profile))
    | Loaded Profile


type ModalStatus
    = Hidden
    | Shown



-- VIEW


view : LoggedIn.Model -> Model -> { title : String, content : Html Msg }
view loggedIn model =
    let
        title =
            case model.status of
                Loaded profile ->
                    Maybe.withDefault "" profile.userName

                _ ->
                    ""

        content =
            case model.status of
                Loading ->
                    Page.fullPageLoading

                LoadingFailed _ ->
                    Page.fullPageError (t loggedIn.shared.translations "profile.title") Http.Timeout

                Loaded profile ->
                    view_ model loggedIn profile
    in
    { title = title
    , content = content
    }


view_ : Model -> LoggedIn.Model -> Profile -> Html Msg
view_ model loggedIn profile =
    let
        text_ str =
            t loggedIn.shared.translations str

        downloadAction =
            case LoggedIn.maybePrivateKey loggedIn of
                Just _ ->
                    DownloadPdf loggedIn.auth.form.enteredPin

                Nothing ->
                    case loggedIn.shared.maybeAccount of
                        Just ( _, True ) ->
                            ClickedViewPrivateKeyAuth

                        _ ->
                            Ignored
    in
    div [ class "grid gap-6 mb-6" ]
        [ PublicProfile.view_ loggedIn profile False
        , div [ class "bg-white" ]
            [ div [ class "container divide-y divide-gray-500 mx-auto px-4" ]
                [ viewAction (text_ "profile.12words.title") [ viewButton (text_ "profile.12words.button") downloadAction ]
                , viewAction (text_ "profile.pin.title") [ viewButton (text_ "profile.pin.button") ClickedChangePin ]
                , viewAction (text_ "notifications.title")
                    [ div
                        [ class "inline-block mr-2" ]
                        [ if model.pushNotifications then
                            label
                                [ for "notifications"
                                , class "cursor-pointer text-indigo-500"
                                ]
                                [ text "enabled" ]

                          else
                            label [ for "notifications", class "cursor-pointer text-gray" ] [ text "disabled" ]
                        ]
                    , toggleView loggedIn.shared.translations model.pushNotifications RequestPush "notifications"
                    ]
                ]
            ]
        , viewNewPinModal model loggedIn.shared
        ]


viewNewPinModal : Model -> Shared -> Html Msg
viewNewPinModal model shared =
    let
        tr str =
            t shared.translations str
    in
    case model.pinModal of
        Shown ->
            div
                [ class "modal container fade-in"
                , stopPropagationOn "click" (Decode.succeed ( Ignored, True ))
                ]
                [ div [ class "modal-bg", onClick ClickedCloseChangePin ] []
                , div [ class "modal-content overflow-auto" ]
                    [ button
                        [ class "absolute top-0 right-0 mx-4 my-4", onClick ClickedCloseChangePin ]
                        [ Icons.close "fill-current text-gray-400"
                        ]
                    , div [ class "display flex flex-col justify-around h-full" ]
                        [ div
                            []
                            [ p [ class "w-full font-medium text-heading text-2xl mb-2" ]
                                [ text (tr "profile.changePin")
                                ]
                            , p [ class "text-sm" ] [ text (tr "profile.changePinPrompt") ]
                            ]
                        , div [ class "mb-4" ]
                            [ Pin.view
                                shared
                                { labelText = tr "profile.newPin"
                                , inputId = "pinInput"
                                , inputValue = Maybe.withDefault "" model.newPin
                                , onInputMsg = EnteredPin
                                , onToggleMsg = TogglePinVisibility
                                , isVisible = True
                                , errors =
                                    case model.newPinErrorMsg of
                                        Just err ->
                                            [ err ]

                                        Nothing ->
                                            []
                                }
                            ]
                        , button [ class "button button-primary w-full", onClick ChangePinSubmitted ] [ text (tr "profile.pin.button") ]
                        ]
                    ]
                ]

        Hidden ->
            text ""


viewButton : String -> Msg -> Html Msg
viewButton label msg =
    button
        [ class "uppercase border border-solid border-gray-500 rounded-full py-2 px-5 leading-none text-orange-300 font-medium"
        , onClick msg
        ]
        [ text label
        ]


viewAction : String -> List (Html Msg) -> Html Msg
viewAction label contents =
    div [ class "flex items-center justify-between py-4" ]
        [ span [ class "text-sm leading-6" ]
            [ text label ]
        , span
            [ class "font-medium text-sm text-right leading-6" ]
            contents
        ]


toggleView : Translations -> Bool -> Msg -> String -> Html Msg
toggleView translations isEnabled toggleFunction inputId =
    div [ class "form-switch inline-block align-middle" ]
        [ input
            [ type_ "checkbox"
            , id inputId
            , name inputId
            , class "form-switch-checkbox"
            , checked isEnabled
            , onClick toggleFunction
            ]
            []
        , label [ class "form-switch-label", for inputId ] []
        ]



-- UPDATE


type alias UpdateResult =
    UR.UpdateResult Model Msg (External Msg)


type Msg
    = Ignored
    | CompletedProfileLoad (Result (Graphql.Http.Error (Maybe Profile)) (Maybe Profile))
    | DownloadPdf String
    | ClickedViewPrivateKeyAuth
    | ClickedChangePin
    | ChangePinSubmitted
    | EnteredPin String
    | ClickedCloseChangePin
    | PinChanged
    | TogglePinVisibility
    | GotPushPreference Bool
    | RequestPush
    | CheckPushPref
    | GotPushSub PushSubscription
    | CompletedPushUpload (Result (Graphql.Http.Error ()) ())


update : Msg -> Model -> LoggedIn.Model -> UpdateResult
update msg model loggedIn =
    let
        t =
            I18Next.t loggedIn.shared.translations

        downloadPdfPort pin =
            UR.addPort
                { responseAddress = Ignored
                , responseData = Encode.null
                , data =
                    Encode.object
                        [ ( "name", Encode.string "downloadAuthPdfFromProfile" )
                        , ( "pin", Encode.string pin )
                        ]
                }
    in
    case msg of
        Ignored ->
            UR.init model

        CompletedProfileLoad (Ok Nothing) ->
            UR.init model

        CompletedProfileLoad (Ok (Just profile)) ->
            UR.init { model | status = Loaded profile }

        CompletedProfileLoad (Err err) ->
            UR.init { model | status = LoadingFailed err }
                |> UR.logGraphqlError msg err

        ClickedChangePin ->
            if LoggedIn.isAuth loggedIn then
                UR.init { model | pinModal = Shown }

            else
                UR.init model
                    |> UR.addExt (Just ClickedChangePin |> RequiredAuthentication)

        TogglePinVisibility ->
            UR.init { model | isNewPinVisible = not model.isNewPinVisible }

        ChangePinSubmitted ->
            if LoggedIn.isAuth loggedIn then
                let
                    oldPin =
                        case model.oldPin of
                            Just pin ->
                                pin

                            Nothing ->
                                loggedIn.auth.form.enteredPin

                    newPin =
                        Maybe.withDefault "" model.newPin
                in
                if Pin.isValid newPin then
                    UR.init model
                        |> UR.addPort
                            { responseAddress = PinChanged
                            , responseData = Encode.null
                            , data =
                                Encode.object
                                    [ ( "name", Encode.string "changePin" )
                                    , ( "oldPin", Encode.string oldPin )
                                    , ( "newPin", Encode.string newPin )
                                    ]
                            }

                else
                    UR.init { model | newPinErrorMsg = Just (t "auth.pin.shouldHaveSixDigitsError") }
                        |> UR.addCmd Cmd.none

            else
                UR.init model
                    |> UR.addExt (Just ClickedChangePin |> RequiredAuthentication)

        EnteredPin newPin ->
            UR.init { model | newPinErrorMsg = Nothing, newPin = Just newPin }

        ClickedCloseChangePin ->
            UR.init { model | pinModal = Hidden }

        PinChanged ->
            { model
                | pinModal = Hidden
                , oldPin = model.newPin
                , newPin = Nothing
            }
                |> UR.init
                |> UR.addExt (ShowFeedback Success (t "profile.pin.successMsg"))

        ClickedViewPrivateKeyAuth ->
            case LoggedIn.maybePrivateKey loggedIn of
                Nothing ->
                    UR.init model
                        |> UR.addExt
                            (Just ClickedViewPrivateKeyAuth
                                |> RequiredAuthentication
                            )

                Just _ ->
                    model
                        |> UR.init
                        |> downloadPdfPort loggedIn.auth.form.enteredPin

        DownloadPdf pin ->
            model
                |> UR.init
                |> downloadPdfPort pin

        GotPushPreference val ->
            { model | pushNotifications = val }
                |> UR.init

        CheckPushPref ->
            model
                |> UR.init
                |> UR.addPort
                    { responseAddress = GotPushPreference False
                    , responseData = Encode.null
                    , data =
                        Encode.object [ ( "name", Encode.string "checkPushPref" ) ]
                    }

        RequestPush ->
            if model.pushNotifications then
                model
                    |> UR.init
                    |> UR.addPort
                        { responseAddress = GotPushPreference False
                        , responseData = Encode.null
                        , data =
                            Encode.object [ ( "name", Encode.string "disablePushPref" ) ]
                        }

            else
                model
                    |> UR.init
                    |> UR.addPort
                        { responseAddress = RequestPush
                        , responseData = Encode.null
                        , data =
                            Encode.object
                                [ ( "name", Encode.string "requestPushPermission" ) ]
                        }

        GotPushSub push ->
            model
                |> UR.init
                |> UR.addCmd
                    (uploadPushSubscription loggedIn push)

        CompletedPushUpload res ->
            case res of
                Ok _ ->
                    model
                        |> UR.init
                        |> UR.addPort
                            { responseAddress = CompletedPushUpload res
                            , responseData = Encode.null
                            , data =
                                Encode.object
                                    [ ( "name", Encode.string "completedPushUpload" ) ]
                            }

                Err err ->
                    model
                        |> UR.init
                        |> UR.logGraphqlError msg err


decodePushPref : Value -> Maybe Msg
decodePushPref val =
    Decode.decodeValue (Decode.field "isSet" Decode.bool) val
        |> Result.map GotPushPreference
        |> Result.toMaybe


uploadPushSubscription : LoggedIn.Model -> PushSubscription -> Cmd Msg
uploadPushSubscription { accountName, shared } data =
    Api.Graphql.mutation shared
        (PushSubscription.activatePushMutation accountName data)
        CompletedPushUpload


jsAddressToMsg : List String -> Value -> Maybe Msg
jsAddressToMsg addr val =
    case addr of
        "ClickedCloseChangePin" :: [] ->
            Just ClickedCloseChangePin

        "PinChanged" :: [] ->
            Just PinChanged

        "RequestPush" :: _ ->
            let
                push =
                    Decode.decodeValue (Decode.field "sub" Decode.string) val
                        |> Result.andThen (Decode.decodeString Decode.value)
                        |> Result.andThen (Decode.decodeValue PushSubscription.decode)
            in
            case push of
                Ok res ->
                    Just (GotPushSub res)

                Err _ ->
                    -- TODO: Handle PushSubscription Decode error
                    Nothing

        "ChangePinSubmitted" :: [] ->
            Just ChangePinSubmitted

        "TogglePinVisibility" :: [] ->
            Just TogglePinVisibility

        "GotPushPreference" :: _ ->
            decodePushPref val

        "CompletedPushUpload" :: _ ->
            decodePushPref val

        _ ->
            Nothing


msgToString : Msg -> List String
msgToString msg =
    case msg of
        Ignored ->
            [ "Ignored" ]

        CompletedProfileLoad r ->
            [ "CompletedProfileLoad", UR.resultToString r ]

        DownloadPdf r ->
            [ "DownloadPdf" ]

        ClickedChangePin ->
            [ "ClickedChangePin" ]

        ClickedCloseChangePin ->
            [ "ClickedCloseChangePin" ]

        PinChanged ->
            [ "PinChanged" ]

        ClickedViewPrivateKeyAuth ->
            [ "ClickedViewPrivateKeyAuth" ]

        TogglePinVisibility ->
            [ "TogglePinVisibility" ]

        ChangePinSubmitted ->
            [ "ChangePinSubmitted" ]

        EnteredPin r ->
            [ "EnteredPin" ]

        GotPushPreference r ->
            [ "GotPushPreference" ]

        RequestPush ->
            [ "RequestPush" ]

        CheckPushPref ->
            [ "CheckPushPref" ]

        GotPushSub _ ->
            [ "GotPushSub" ]

        CompletedPushUpload _ ->
            [ "CompletedPushUpload" ]
