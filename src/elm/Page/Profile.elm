module Page.Profile exposing (Model, Msg, init, jsAddressToMsg, msgToString, update, view, viewInfo, viewSettings)

import Api.Graphql
import Avatar
import Browser.Dom as Dom
import Eos exposing (Symbol)
import Eos.Account as Eos
import Graphql.Http
import Html exposing (Html, a, button, div, input, label, li, p, span, text, ul)
import Html.Attributes exposing (checked, class, classList, for, id, name, type_)
import Html.Events exposing (onClick)
import Http
import I18Next exposing (t)
import Icons
import Json.Decode as Decode exposing (Value)
import Json.Encode as Encode
import Page
import Profile exposing (Profile)
import PushSubscription exposing (PushSubscription)
import Route
import Session.LoggedIn as LoggedIn exposing (External(..), FeedbackStatus(..))
import Session.Shared exposing (Shared)
import Task
import UpdateResult as UR
import View.Modal as Modal
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
    , currentPin : Maybe String
    , isNewPinModalVisible : Bool
    , newPin : Maybe String
    , isNewPinReadable : Bool
    , newPinErrorMsg : Maybe String
    , isPushNotificationsEnabled : Bool
    , maybePdfDownloadedSuccessfully : Maybe Bool
    , isDisallowKycModalShowed : Bool
    }


initModel : LoggedIn.Model -> Model
initModel _ =
    { status = Loading
    , currentPin = Nothing
    , isNewPinModalVisible = False
    , newPin = Nothing
    , isNewPinReadable = True
    , newPinErrorMsg = Nothing
    , isPushNotificationsEnabled = False
    , maybePdfDownloadedSuccessfully = Nothing
    , isDisallowKycModalShowed = False
    }


type Status
    = Loading
    | LoadingFailed (Graphql.Http.Error (Maybe Profile))
    | Loaded Profile



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
                    div []
                        [ Page.viewHeader loggedIn (t loggedIn.shared.translations "menu.profile") Route.Dashboard
                        , viewInfo loggedIn
                            profile
                            { hasTransferButton = False
                            , hasKyc = True
                            , hasEditLink = True
                            }
                        , viewSettings loggedIn model
                        , viewNewPinModal model loggedIn.shared
                        , viewDownloadPdfErrorModal model loggedIn
                        , viewDisallowKycModal model
                        ]
    in
    { title = title
    , content = content
    }


viewDisallowKycModal : Model -> Html Msg
viewDisallowKycModal model =
    Modal.initWith
        { closeMsg = ToggleDisallowKycModal
        , isVisible = model.isDisallowKycModalShowed
        }
        |> Modal.withHeader "Disallow KYC data"
        |> Modal.withBody
            [ div []
                [ text "Are you sure want to disallow your KYC data? You will not be able to participate to the community."
                ]
            ]
        |> Modal.withFooter
            [ button
                [ class "modal-cancel"
                , onClick ToggleDisallowKycModal
                ]
                [ text "No" ]
            , button [ class "modal-accept" ]
                [ text "Yes" ]
            ]
        |> Modal.toHtml


viewSettings : LoggedIn.Model -> Model -> Html Msg
viewSettings loggedIn model =
    let
        tr str =
            t loggedIn.shared.translations str

        downloadAction =
            case LoggedIn.maybePrivateKey loggedIn of
                Just _ ->
                    let
                        currentPin =
                            case model.currentPin of
                                -- The case when "Download" PDF button pressed just after changing the PIN
                                Just pin ->
                                    pin

                                Nothing ->
                                    loggedIn.auth.form.enteredPin
                    in
                    DownloadPdf currentPin

                Nothing ->
                    case loggedIn.shared.maybeAccount of
                        Just ( _, True ) ->
                            ClickedViewPrivateKeyAuth

                        _ ->
                            Ignored
    in
    div [ class "bg-white mb-6" ]
        [ ul [ class "container divide-y divide-gray-500 mx-auto px-4" ]
            [ viewProfileItem
                (text (tr "profile.12words.title"))
                (viewButton (tr "profile.12words.button") downloadAction)
                Center
                Nothing
            , viewProfileItem
                (text (tr "profile.pin.title"))
                (viewButton (tr "profile.pin.button") ClickedChangePin)
                Center
                Nothing
            , viewProfileItem
                (text (tr "notifications.title"))
                (viewTogglePush loggedIn model)
                Center
                Nothing

            -- if community.hasKyc
            , viewProfileItem
                (span []
                    [ text (tr "KYC data")
                    , span [ class "icon-tooltip inline-block align-center ml-1" ]
                        [ Icons.question "inline-block"
                        , p
                            [ class "icon-tooltip-content" ]
                            [ text "KYC means Know Your Customer and sometimes Know Your Client. KYC check is the mandatory process of identifying and verifying the identity of the client when opening an account and periodically over time."
                            ]
                        ]
                    ]
                )
                (viewDangerButton "Disallow" ToggleDisallowKycModal)
                Center
                (Just
                    (div [ class "uppercase text-red pt-2 text-xs" ]
                        [ text "important: if you disallow the use in the app, you will have no access to this community until informing us this data again."
                        ]
                    )
                )
            ]
        ]


type alias PublicInfoConfig =
    { hasTransferButton : Bool
    , hasKyc : Bool
    , hasEditLink : Bool
    }


viewInfo : LoggedIn.Model -> Profile -> PublicInfoConfig -> Html msg
viewInfo loggedIn profile { hasTransferButton, hasKyc, hasEditLink } =
    let
        tr txt =
            t loggedIn.shared.translations txt

        userName =
            Maybe.withDefault "" profile.userName

        email =
            Maybe.withDefault "" profile.email

        bio =
            Maybe.withDefault "" profile.bio

        location =
            Maybe.withDefault "" profile.localization

        account =
            Eos.nameToString profile.account
    in
    div [ class "bg-white mb-6" ]
        [ div [ class "container p-4 mx-auto" ]
            [ div
                [ classList <|
                    let
                        hasBottomBorder =
                            not hasTransferButton
                    in
                    [ ( "pb-4", True )
                    , ( "border-b border-gray-500", hasBottomBorder )
                    ]
                ]
                [ div [ class "flex mb-4 items-center flex-wrap" ]
                    [ Avatar.view profile.avatar "w-20 h-20 mr-6 xs-max:w-16 xs-max:h-16 xs-max:mr-3"
                    , div [ class "flex-grow flex items-center justify-between" ]
                        [ ul [ class "text-sm text-gray-900" ]
                            [ li [ class "font-medium text-body-black text-2xl xs-max:text-xl" ]
                                [ text userName ]
                            , li [] [ text email ]
                            , li [] [ text account ]
                            ]
                        , if hasEditLink then
                            a
                                [ class "ml-2"
                                , Route.href Route.ProfileEditor
                                ]
                                [ Icons.edit "" ]

                          else
                            text ""
                        ]
                    ]
                , p [ class "text-sm text-gray-900" ]
                    [ text bio ]
                ]
            , if hasTransferButton then
                viewTransferButton
                    loggedIn.shared
                    loggedIn.selectedCommunity
                    account

              else
                text ""
            , ul [ class "divide-y divide-gray-500" ]
                ([ viewProfileItem
                    (text (tr "profile.locations"))
                    (text location)
                    Center
                    Nothing
                 , viewProfileItem
                    (text (tr "profile.interests"))
                    (text (String.join ", " profile.interests))
                    Top
                    Nothing
                 ]
                    ++ (if hasKyc then
                            [ viewProfileItem
                                (text (tr "Phone Number"))
                                (text "12341234")
                                Center
                                Nothing
                            , viewProfileItem
                                (text (tr "Cedula de Identidad"))
                                (text "12341234")
                                Center
                                Nothing
                            ]

                        else
                            []
                       )
                )
            ]
        ]


type VerticalAlign
    = Top
    | Center


viewProfileItem : Html msg -> Html msg -> VerticalAlign -> Maybe (Html msg) -> Html msg
viewProfileItem lbl content vAlign extraContent =
    let
        vAlignClass =
            case vAlign of
                Top ->
                    "items-start"

                Center ->
                    "items-center"
    in
    li
        [ class "py-4" ]
        [ div
            [ class "flex justify-between"
            , class vAlignClass
            ]
            [ span [ class "text-sm leading-6 mr-4" ]
                [ lbl ]
            , span [ class "text-indigo-500 font-medium text-sm text-right" ]
                [ content ]
            ]
        , case extraContent of
            Just extra ->
                extra

            Nothing ->
                text ""
        ]


viewTransferButton : Shared -> Symbol -> String -> Html msg
viewTransferButton shared symbol user =
    let
        text_ s =
            text (t shared.translations s)
    in
    div [ class "mt-3 mb-2" ]
        [ a
            [ class "button button-primary w-full"
            , Route.href (Route.Transfer symbol (Just user))
            ]
            [ text_ "transfer.title" ]
        ]


viewDownloadPdfErrorModal : Model -> LoggedIn.Model -> Html Msg
viewDownloadPdfErrorModal model loggedIn =
    let
        modalVisibility =
            case model.maybePdfDownloadedSuccessfully of
                Just isDownloaded ->
                    not isDownloaded

                Nothing ->
                    False

        privateKey =
            case LoggedIn.maybePrivateKey loggedIn of
                Nothing ->
                    ""

                Just pk ->
                    pk

        body =
            [ p [ class "my-3" ]
                [ text "Please, check if you have your 12 words saved during the registration process and use them for further signing in."
                ]
            , p [ class "my-3" ]
                [ text "If you completely lost your 12 words, please, contact us and provide this private key and we will help you to recover:"
                ]
            , p [ class "font-bold my-3 text-lg text-center border p-4 rounded-sm bg-gray-100" ]
                [ text privateKey
                ]
            ]
    in
    Modal.initWith
        { closeMsg = ClickedClosePdfDownloadError
        , isVisible = modalVisibility
        }
        |> Modal.withHeader "Sorry, we can't find your 12 words"
        |> Modal.withBody body
        |> Modal.toHtml


viewNewPinModal : Model -> Shared -> Html Msg
viewNewPinModal model shared =
    let
        tr str =
            t shared.translations str

        pinField =
            Pin.view
                shared
                { labelText = tr "profile.newPin"
                , inputId = "pinInput"
                , inputValue = Maybe.withDefault "" model.newPin
                , onInputMsg = EnteredPin
                , onToggleMsg = TogglePinReadability
                , isVisible = True
                , errors =
                    case model.newPinErrorMsg of
                        Just err ->
                            [ err ]

                        Nothing ->
                            []
                }

        body =
            [ div []
                [ p [ class "text-sm" ]
                    [ text (tr "profile.changePinPrompt") ]
                ]
            , div [ class "mb-4" ] [ pinField ]
            , button
                [ class "button button-primary w-full"
                , onClick ChangePinSubmitted
                ]
                [ text (tr "profile.pin.button") ]
            ]
    in
    Modal.initWith
        { closeMsg = ClickedCloseChangePin
        , isVisible = model.isNewPinModalVisible
        }
        |> Modal.withHeader (tr "profile.changePin")
        |> Modal.withBody body
        |> Modal.toHtml


viewButton : String -> Msg -> Html Msg
viewButton label msg =
    button
        [ class "button-secondary uppercase button-sm"
        , onClick msg
        ]
        [ text label
        ]


viewDangerButton : String -> Msg -> Html Msg
viewDangerButton label msg =
    button
        [ class "button-secondary uppercase button-sm text-red border-red"
        , onClick msg
        ]
        [ text label
        ]


viewTogglePush : LoggedIn.Model -> Model -> Html Msg
viewTogglePush loggedIn model =
    let
        tr str =
            t loggedIn.shared.translations str

        inputId =
            "notifications"

        lblColor =
            if model.isPushNotificationsEnabled then
                "text-indigo-500"

            else
                "text-gray"

        lblText =
            if model.isPushNotificationsEnabled then
                tr "settings.features.enabled"

            else
                tr "settings.features.disabled"
    in
    div []
        [ label
            [ for inputId
            , class "inline-block lowercase mr-2 cursor-pointer"
            , class lblColor
            ]
            [ text lblText ]
        , div [ class "form-switch inline-block align-middle" ]
            [ input
                [ type_ "checkbox"
                , id inputId
                , name inputId
                , class "form-switch-checkbox"
                , checked model.isPushNotificationsEnabled
                , onClick RequestPush
                ]
                []
            , label [ class "form-switch-label", for inputId ] []
            ]
        ]



-- UPDATE


type alias UpdateResult =
    UR.UpdateResult Model Msg (External Msg)


type Msg
    = Ignored
    | CompletedProfileLoad (Result (Graphql.Http.Error (Maybe Profile)) (Maybe Profile))
    | DownloadPdf String
    | DownloadPdfProcessed Bool
    | ClickedClosePdfDownloadError
    | ClickedViewPrivateKeyAuth
    | ClickedChangePin
    | ChangePinSubmitted
    | EnteredPin String
    | ClickedCloseChangePin
    | PinChanged
    | TogglePinReadability
    | GotPushPreference Bool
    | RequestPush
    | ToggleDisallowKycModal
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
                { responseAddress = DownloadPdfProcessed False
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

        ToggleDisallowKycModal ->
            { model | isDisallowKycModalShowed = not model.isDisallowKycModalShowed }
                |> UR.init

        CompletedProfileLoad (Ok Nothing) ->
            UR.init model

        CompletedProfileLoad (Ok (Just profile)) ->
            UR.init { model | status = Loaded profile }

        CompletedProfileLoad (Err err) ->
            UR.init { model | status = LoadingFailed err }
                |> UR.logGraphqlError msg err

        ClickedChangePin ->
            if LoggedIn.isAuth loggedIn then
                UR.init { model | isNewPinModalVisible = True }
                    |> UR.addCmd
                        (Dom.focus "pinInput"
                            |> Task.attempt (\_ -> Ignored)
                        )

            else
                UR.init model
                    |> UR.addExt (Just ClickedChangePin |> RequiredAuthentication)
                    |> UR.addCmd
                        (Dom.focus "pinInput"
                            |> Task.attempt (\_ -> Ignored)
                        )

        TogglePinReadability ->
            UR.init { model | isNewPinReadable = not model.isNewPinReadable }

        ChangePinSubmitted ->
            if LoggedIn.isAuth loggedIn then
                let
                    currentPin =
                        case model.currentPin of
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
                                    , ( "currentPin", Encode.string currentPin )
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
            UR.init { model | isNewPinModalVisible = False }

        PinChanged ->
            { model
                | isNewPinModalVisible = False
                , currentPin = model.newPin
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
                        |> UR.addCmd
                            (Dom.focus "pinInput"
                                |> Task.attempt (\_ -> Ignored)
                            )

                Just _ ->
                    model
                        |> UR.init
                        |> downloadPdfPort loggedIn.auth.form.enteredPin

        DownloadPdf pin ->
            model
                |> UR.init
                |> downloadPdfPort pin

        DownloadPdfProcessed isDownloaded ->
            { model | maybePdfDownloadedSuccessfully = Just isDownloaded }
                |> UR.init

        ClickedClosePdfDownloadError ->
            { model | maybePdfDownloadedSuccessfully = Nothing }
                |> UR.init

        GotPushPreference val ->
            { model | isPushNotificationsEnabled = val }
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
            if model.isPushNotificationsEnabled then
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


decodeIsPdfDownloaded : Value -> Maybe Msg
decodeIsPdfDownloaded val =
    Decode.decodeValue (Decode.field "isDownloaded" Decode.bool) val
        |> Result.map DownloadPdfProcessed
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

        "DownloadPdfProcessed" :: _ ->
            decodeIsPdfDownloaded val

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
                    Nothing

        "ChangePinSubmitted" :: [] ->
            Just ChangePinSubmitted

        "TogglePinReadability" :: [] ->
            Just TogglePinReadability

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

        ToggleDisallowKycModal ->
            [ "DisallowKycClicked" ]

        CompletedProfileLoad r ->
            [ "CompletedProfileLoad", UR.resultToString r ]

        DownloadPdf _ ->
            [ "DownloadPdf" ]

        DownloadPdfProcessed _ ->
            [ "DownloadPdfProcessed" ]

        ClickedClosePdfDownloadError ->
            [ "ClickedClosePdfDownloadError" ]

        ClickedChangePin ->
            [ "ClickedChangePin" ]

        ClickedCloseChangePin ->
            [ "ClickedCloseChangePin" ]

        PinChanged ->
            [ "PinChanged" ]

        ClickedViewPrivateKeyAuth ->
            [ "ClickedViewPrivateKeyAuth" ]

        TogglePinReadability ->
            [ "TogglePinReadability" ]

        ChangePinSubmitted ->
            [ "ChangePinSubmitted" ]

        EnteredPin _ ->
            [ "EnteredPin" ]

        GotPushPreference _ ->
            [ "GotPushPreference" ]

        RequestPush ->
            [ "RequestPush" ]

        CheckPushPref ->
            [ "CheckPushPref" ]

        GotPushSub _ ->
            [ "GotPushSub" ]

        CompletedPushUpload _ ->
            [ "CompletedPushUpload" ]
