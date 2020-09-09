module Page.Register exposing (Model, Msg, init, jsAddressToMsg, msgToString, update, view)

import Address
import Api.Graphql
import Cambiatus.Enum.SignUpStatus as SignUpStatus
import Cambiatus.InputObject as InputObject
import Cambiatus.Mutation as Mutation
import Cambiatus.Object.SignUp
import Community exposing (Invite)
import Eos.Account as Eos
import Graphql.Http
import Graphql.SelectionSet exposing (with)
import Html exposing (Html, a, button, div, img, input, label, p, span, strong, text)
import Html.Attributes exposing (checked, class, disabled, for, id, src, style, type_, value)
import Html.Events exposing (onCheck, onClick, onSubmit)
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode
import Page.Register.DefaultForm as DefaultForm
import Page.Register.JuridicalForm as JuridicalForm
import Page.Register.NaturalForm as NaturalForm
import Route
import Session.Guest as Guest exposing (External(..))
import Session.Shared exposing (Shared, Translators)
import UpdateResult as UR
import Validate



-- INIT


queries : Maybe String -> Shared -> Cmd Msg
queries maybeInvitationId shared =
    case maybeInvitationId of
        Just invitation ->
            Cmd.batch
                [ Api.Graphql.query shared (Community.inviteQuery invitation) CompletedLoadInvite
                , Api.Graphql.query shared (Address.countryQuery "Costa Rica") CompletedLoadCountry
                ]

        Nothing ->
            Cmd.none


init : Maybe String -> Guest.Model -> ( Model, Cmd Msg )
init maybeInvitationId guest =
    ( initModel maybeInvitationId guest
    , queries maybeInvitationId guest.shared
    )



-- MODEL


type alias Model =
    { accountKeys : Maybe AccountKeys
    , hasAgreedToSavePassphrase : Bool
    , isPassphraseCopiedToClipboard : Bool
    , serverError : Maybe String
    , status : Status
    , maybeInvitationId : Maybe String
    , selectedForm : FormType
    , country : Maybe Address.Country
    }


type AccountType
    = NaturalAccount
    | JuridicalAccount


type FormType
    = None
    | Natural NaturalForm.Model
    | Juridical JuridicalForm.Model
    | Default DefaultForm.Model


initModel : Maybe String -> Guest.Model -> Model
initModel maybeInvitationId _ =
    { accountKeys = Nothing
    , hasAgreedToSavePassphrase = False
    , isPassphraseCopiedToClipboard = False
    , serverError = Nothing
    , status =
        case maybeInvitationId of
            Just _ ->
                Loading

            Nothing ->
                LoadedDefaultCommunity
    , maybeInvitationId = maybeInvitationId
    , selectedForm =
        case maybeInvitationId of
            Just _ ->
                None

            Nothing ->
                Default DefaultForm.init
    , country = Nothing
    }



---- ACCOUNT KEYS


type alias AccountKeys =
    { ownerKey : String
    , activeKey : String
    , accountName : Eos.Name
    , transactionId : String
    , words : String
    , privateKey : String
    }


decodeAccount : Decoder AccountKeys
decodeAccount =
    Decode.succeed AccountKeys
        |> Decode.required "ownerKey" Decode.string
        |> Decode.required "activeKey" Decode.string
        |> Decode.required "accountName" Eos.nameDecoder
        |> Decode.required "transactionId" Decode.string
        |> Decode.required "words" Decode.string
        |> Decode.required "privateKey" Decode.string


decodeAvailabilityResponse : Decoder (Result String Bool)
decodeAvailabilityResponse =
    let
        toDecoder : Bool -> String -> Decoder (Result String Bool)
        toDecoder isAvailable error =
            if String.length error < 0 then
                Decode.succeed (Result.Ok isAvailable)

            else
                Decode.succeed (Result.Err error)
    in
    Decode.succeed toDecoder
        |> Decode.required "isAvailable" Decode.bool
        |> Decode.required "error" Decode.string
        |> Decode.resolve



-- VIEW


view : Guest.Model -> Model -> { title : String, content : Html Msg }
view guest model =
    let
        shared =
            guest.shared

        { t } =
            shared.translators
    in
    { title =
        t "register.registerTab"
    , content =
        viewCreateAccount guest.shared.translators model

    -- if model.accountGenerated then
    --     viewAccountGenerated
    -- else
    --     viewCreateAccount
    }


viewAccountGenerated : Translators -> Model -> AccountKeys -> Html Msg
viewAccountGenerated ({ t } as translators) model keys =
    let
        name =
            Eos.nameToString keys.accountName

        passphraseTextId =
            "passphraseText"

        passphraseInputId =
            -- Passphrase text is duplicated in `input:text` to be able to copy via Browser API
            "passphraseWords"
    in
    div
        [ class "flex-grow bg-purple-500 flex md:block"
        ]
        [ div
            [ class "sf-wrapper"
            , class "px-4 md:max-w-sm md:mx-auto md:pt-20 md:px-0 text-white text-body"
            ]
            [ div [ class "sf-content" ]
                [ viewTitleForStep translators 2
                , p
                    [ class "text-xl mb-3" ]
                    [ text (t "register.account_created.greet")
                    , text " "
                    , strong [] [ text name ]
                    , text ", "
                    , text (t "register.account_created.last_step")
                    ]
                , p [ class "mb-3" ]
                    [ text (t "register.account_created.instructions")
                    ]
                , div [ class "w-1/4 m-auto relative left-1" ]
                    [ img [ src "images/reg-passphrase-boy.svg" ]
                        []
                    , img
                        [ class "absolute w-1/4 -mt-2 -ml-10"
                        , src "images/reg-passphrase-boy-hand.svg"
                        ]
                        []
                    ]
                , div [ class "bg-white text-black text-2xl mb-12 p-4 rounded-lg" ]
                    [ p [ class "input-label" ]
                        [ text (t "register.account_created.twelve_words")
                        , if model.isPassphraseCopiedToClipboard then
                            strong [ class "uppercase ml-1" ]
                                [ text (t "register.account_created.words_copied")
                                , text " ✔"
                                ]

                          else
                            text ""
                        ]
                    , p
                        [ class "pb-2 leading-tight" ]
                        [ span [ id passphraseTextId ] [ text keys.words ]
                        , input
                            -- We use `HTMLInputElement.select()` method in port to select and copy the text. This method
                            -- works only with `input` and `textarea` elements which has to be presented in DOM (e.g. we can't
                            -- hide it with `display: hidden`), so we hide it using position and opacity.
                            [ type_ "text"
                            , class "absolute opacity-0"
                            , style "left" "-9999em"
                            , id passphraseInputId
                            , value keys.words
                            ]
                            []
                        ]
                    , button
                        [ class "button m-auto button-primary button-sm"
                        , onClick <| CopyToClipboard passphraseInputId
                        ]
                        [ text (t "register.account_created.copy") ]
                    ]
                ]
            , div [ class "sf-footer" ]
                [ div [ class "my-4" ]
                    [ label [ class "form-label block" ]
                        [ input
                            [ type_ "checkbox"
                            , class "form-checkbox mr-2 p-1"
                            , checked model.hasAgreedToSavePassphrase
                            , onCheck AgreedToSave12Words
                            ]
                            []
                        , text (t "register.account_created.i_saved_words")
                        , text " 💜"
                        ]
                    ]
                , button
                    [ onClick <| DownloadPdf (pdfData keys)
                    , class "button button-primary w-full mb-8"
                    , disabled (not model.hasAgreedToSavePassphrase)
                    , class <|
                        if model.hasAgreedToSavePassphrase then
                            ""

                        else
                            "button-disabled text-gray-600"
                    ]
                    [ text (t "register.account_created.download") ]
                ]
            ]
        ]


viewCreateAccount : Translators -> Model -> Html Msg
viewCreateAccount translators model =
    let
        formElement element =
            div [ class "flex justify-center flex-grow bg-white" ]
                [ Html.form
                    [ class "flex flex-grow flex-col bg-white px-4 px-0 md:max-w-sm sf-wrapper"
                    , onSubmit (ValidateForm model.selectedForm)
                    ]
                    (viewServerError model.serverError :: element)
                ]

        defaultForm =
            case model.selectedForm of
                Default form ->
                    formElement [ DefaultForm.view translators form |> Html.map DefaultFormMsg1, viewFooter translators ]

                _ ->
                    div [] []
    in
    case model.status of
        LoadedAll invitation _ ->
            if invitation.community.hasKyc == True then
                formElement [ viewKycRegister translators model, viewFooter translators ]

            else
                defaultForm

        LoadedDefaultCommunity ->
            defaultForm

        Loading ->
            Session.Shared.viewFullLoading

        Generated keys ->
            viewAccountGenerated translators model keys

        LoadedInvite _ ->
            Session.Shared.viewFullLoading

        LoadedCountry _ ->
            Session.Shared.viewFullLoading

        FailedInvite _ ->
            Debug.todo "Implement error"

        FailedCountry _ ->
            Debug.todo "Implement error"

        NotFound ->
            Debug.todo "Implement not found"


viewServerError : Maybe String -> Html msg
viewServerError error =
    case error of
        Just message ->
            div [ class "bg-red border-lg rounded p-4 mt-2 text-white" ] [ text message ]

        Nothing ->
            text ""


viewFooter : Translators -> Html msg
viewFooter translators =
    div [ class "mt-auto flex flex-col justify-between items-center h-32" ]
        [ span []
            [ text (translators.t "register.login")
            , a [ class "underline text-orange-300", Route.href (Route.Login Nothing) ] [ text (translators.t "register.authLink") ]
            ]
        , viewSubmitButton translators
        ]


viewKycRegister : Translators -> Model -> Html Msg
viewKycRegister translators model =
    div []
        [ viewFormTypeSelector translators model
        , div [ class "sf-content" ]
            (case model.maybeInvitationId of
                Just _ ->
                    let
                        selectedForm =
                            case model.selectedForm of
                                Natural form ->
                                    [ NaturalForm.view translators form |> Html.map NaturalFormMsg ]

                                Juridical form ->
                                    [ JuridicalForm.view translators form |> Html.map JuridicalFormMsg ]

                                Default form ->
                                    [ DefaultForm.view translators form |> Html.map DefaultFormMsg ]

                                None ->
                                    []
                    in
                    case model.status of
                        LoadedAll _ _ ->
                            selectedForm

                        LoadedDefaultCommunity ->
                            selectedForm

                        LoadedInvite _ ->
                            [ Session.Shared.viewFullLoading ]

                        LoadedCountry _ ->
                            [ Session.Shared.viewFullLoading ]

                        Loading ->
                            [ Session.Shared.viewFullLoading ]

                        FailedCountry _ ->
                            Debug.todo "Implement error"

                        FailedInvite _ ->
                            Debug.todo "Implement error"

                        NotFound ->
                            Debug.todo "Implement not found"

                        Generated _ ->
                            Debug.todo "Account Generated page"

                Nothing ->
                    []
            )
            |> Html.map FormMsg
        ]


viewSubmitButton : Translators -> Html msg
viewSubmitButton translators =
    button [ class "button button-primary w-full mb-4" ] [ text (translators.t "auth.login.continue") ]


viewFormTypeSelector : Translators -> Model -> Html Msg
viewFormTypeSelector translators model =
    div [ class "flex w-full justify-center" ]
        [ viewFormTypeRadio
            { type_ = NaturalAccount
            , label = translators.t "register.form.types.natural"
            , styles = ""
            , isSelected =
                case model.selectedForm of
                    Natural _ ->
                        True

                    _ ->
                        False
            , onClick = AccountTypeSelected
            }
        , viewFormTypeRadio
            { type_ = JuridicalAccount
            , label = translators.t "register.form.types.juridical"
            , styles = "ml-4"
            , isSelected =
                case model.selectedForm of
                    Juridical _ ->
                        True

                    _ ->
                        False
            , onClick = AccountTypeSelected
            }
        ]


type alias FormTypeRadioOptions a =
    { type_ : AccountType
    , label : String
    , styles : String
    , isSelected : Bool
    , onClick : AccountType -> a
    }


viewFormTypeRadio : FormTypeRadioOptions Msg -> Html Msg
viewFormTypeRadio options =
    let
        defaultClasses =
            "w-40 h-10 rounded-sm flex justify-center items-center cursor-pointer "

        ifSelectedClasses =
            "bg-orange-300 text-white "

        unselectedClasses =
            "bg-gray-100 text-black "

        finalClasses =
            defaultClasses
                ++ (if options.isSelected then
                        ifSelectedClasses

                    else
                        unselectedClasses
                   )

        id =
            case options.type_ of
                NaturalAccount ->
                    "natural"

                JuridicalAccount ->
                    "juridical"
    in
    div [ class (finalClasses ++ options.styles), onClick (options.onClick options.type_) ]
        [ label [ class "cursor-pointer", for id ] [ text options.label ]
        , input [ class "hidden", type_ "radio", checked options.isSelected, onClick (options.onClick options.type_) ] []
        ]


viewTitleForStep : Translators -> Int -> Html msg
viewTitleForStep translators s =
    let
        { t, tr } =
            translators

        step =
            String.fromInt s
    in
    p
        [ class "py-4 mb-4 text-body border-b border-dotted text-grey border-grey-500" ]
        [ text (tr "register.form.step" [ ( "stepNum", step ) ])
        , text " / "
        , strong
            [ class <|
                if s == 1 then
                    "text-black"

                else
                    "text-white"
            ]
            [ text <| t ("register.form.step" ++ step ++ "_title") ]
        ]


pdfData : AccountKeys -> PdfData
pdfData keys =
    { passphrase = keys.words
    , accountName = Eos.nameToString keys.accountName
    }



-- UPDATE


type alias UpdateResult =
    UR.UpdateResult Model Msg External


type Msg
    = ValidateForm FormType
    | GotAccountAvailabilityResponse (Result String Bool)
    | AccountGenerated (Result Decode.Error AccountKeys)
    | AgreedToSave12Words Bool
    | DownloadPdf PdfData
    | PdfDownloaded
    | CopyToClipboard String
    | CopiedToClipboard
    | CompletedLoadInvite (Result (Graphql.Http.Error (Maybe Invite)) (Maybe Invite))
    | CompletedLoadCountry (Result (Graphql.Http.Error (Maybe Address.Country)) (Maybe Address.Country))
    | AccountTypeSelected AccountType
    | FormMsg EitherFormMsg
    | DefaultFormMsg1 DefaultForm.Msg
    | CompletedSignUp (Result (Graphql.Http.Error (Maybe SignUpResponse)) (Maybe SignUpResponse))


type EitherFormMsg
    = JuridicalFormMsg JuridicalForm.Msg
    | NaturalFormMsg NaturalForm.Msg
    | DefaultFormMsg DefaultForm.Msg


type Status
    = LoadedInvite Invite
    | LoadedCountry Address.Country
    | LoadedAll Invite Address.Country
    | Loading
    | FailedInvite (Graphql.Http.Error (Maybe Invite))
    | FailedCountry (Graphql.Http.Error (Maybe Address.Country))
    | NotFound
    | LoadedDefaultCommunity
    | Generated AccountKeys


type alias PdfData =
    { passphrase : String
    , accountName : String
    }


update : Maybe String -> Msg -> Model -> Guest.Model -> UpdateResult
update maybeInvitation msg model guest =
    let
        { t } =
            guest.shared.translators
    in
    case msg of
        ValidateForm formType ->
            let
                validateForm validator form =
                    case Validate.validate validator form of
                        Ok _ ->
                            form.problems

                        Err err ->
                            err

                account =
                    case formType of
                        Juridical form ->
                            Just form.account

                        Natural form ->
                            Just form.account

                        Default form ->
                            Just form.account

                        None ->
                            Nothing
            in
            { model
                | selectedForm =
                    let
                        translators =
                            guest.shared.translators
                    in
                    case formType of
                        Juridical form ->
                            Juridical
                                { form
                                    | problems = validateForm (JuridicalForm.validator translators) form
                                }

                        Natural form ->
                            Natural
                                { form
                                    | problems = validateForm (NaturalForm.validator translators) form
                                }

                        Default form ->
                            Default
                                { form
                                    | problems = validateForm (DefaultForm.validator translators) form
                                }

                        None ->
                            None
            }
                |> UR.init
                |> UR.addPort
                    { responseAddress = ValidateForm formType
                    , responseData = Encode.null
                    , data =
                        Encode.object
                            [ ( "name", Encode.string "checkAccountAvailability" )
                            , ( "account", Encode.string (Maybe.withDefault "" account) )
                            ]
                    }

        FormMsg formMsg ->
            case formMsg of
                JuridicalFormMsg innerMsg ->
                    case model.selectedForm of
                        Juridical form ->
                            UR.init { model | selectedForm = Juridical (JuridicalForm.update innerMsg form) }

                        _ ->
                            UR.init model

                NaturalFormMsg innerMsg ->
                    case model.selectedForm of
                        Natural form ->
                            UR.init { model | selectedForm = Natural (NaturalForm.update innerMsg form) }

                        _ ->
                            UR.init model

                DefaultFormMsg innerMsg ->
                    case model.selectedForm of
                        Default form ->
                            UR.init { model | selectedForm = Default (DefaultForm.update innerMsg form) }

                        _ ->
                            UR.init model

        DefaultFormMsg1 formMsg ->
            case model.selectedForm of
                Default form ->
                    UR.init { model | selectedForm = Default (DefaultForm.update formMsg form) }

                _ ->
                    UR.init model

        AccountTypeSelected type_ ->
            UR.init
                { model
                    | selectedForm =
                        case ( type_, model.status ) of
                            ( NaturalAccount, _ ) ->
                                Natural NaturalForm.init

                            ( JuridicalAccount, LoadedAll _ country ) ->
                                Juridical (JuridicalForm.init country)

                            _ ->
                                model.selectedForm
                }

        GotAccountAvailabilityResponse response ->
            case response of
                Ok isAvailable ->
                    if isAvailable == True then
                        model
                            |> UR.init
                            |> UR.addPort
                                { responseAddress = GotAccountAvailabilityResponse (Result.Ok False)
                                , responseData = Encode.null
                                , data =
                                    Encode.object
                                        [ ( "name", Encode.string "generateAccount" )
                                        , ( "invitationId"
                                          , case maybeInvitation of
                                                Nothing ->
                                                    Encode.null

                                                Just invitationId ->
                                                    Encode.string invitationId
                                          )
                                        , ( "account"
                                          , Encode.string
                                                (case model.selectedForm of
                                                    Juridical form ->
                                                        form.account

                                                    Natural form ->
                                                        form.account

                                                    Default form ->
                                                        form.account

                                                    None ->
                                                        ""
                                                )
                                          )
                                        ]
                                }

                    else
                        UR.init
                            { model
                                | selectedForm =
                                    case model.selectedForm of
                                        Juridical form ->
                                            Juridical { form | problems = ( JuridicalForm.Account, t "error.alreadyTaken" ) :: form.problems }

                                        Natural form ->
                                            Natural { form | problems = ( NaturalForm.Account, t "error.alreadyTaken" ) :: form.problems }

                                        Default form ->
                                            Default { form | problems = ( DefaultForm.Account, t "error.alreadyTaken" ) :: form.problems }

                                        None ->
                                            model.selectedForm
                            }

                Err _ ->
                    UR.init
                        { model
                            | serverError = Just (t "error.unknown")
                        }

        AccountGenerated (Err v) ->
            UR.init
                model
                |> UR.logDecodeError msg v

        AccountGenerated (Ok account) ->
            { model | status = Generated account }
                |> UR.init

        AgreedToSave12Words val ->
            { model | hasAgreedToSavePassphrase = val }
                |> UR.init

        CopyToClipboard elementId ->
            model
                |> UR.init
                |> UR.addPort
                    { responseAddress = CopiedToClipboard
                    , responseData = Encode.null
                    , data =
                        Encode.object
                            [ ( "id", Encode.string elementId )
                            , ( "name", Encode.string "copyToClipboard" )
                            ]
                    }

        CopiedToClipboard ->
            { model | isPassphraseCopiedToClipboard = True }
                |> UR.init

        DownloadPdf { passphrase, accountName } ->
            model
                |> UR.init
                |> UR.addPort
                    { responseAddress = PdfDownloaded
                    , responseData = Encode.null
                    , data =
                        Encode.object
                            [ ( "name", Encode.string "downloadAuthPdfFromRegistration" )
                            , ( "accountName", Encode.string accountName )
                            , ( "passphrase", Encode.string passphrase )
                            ]
                    }

        PdfDownloaded ->
            model
                |> UR.init
                |> UR.addCmd
                    (case model.status of
                        Generated keys ->
                            formTypeToCmd guest.shared keys.ownerKey model.selectedForm

                        _ ->
                            Cmd.none
                    )

        CompletedSignUp (Ok _) ->
            model
                |> UR.init
                |> UR.addCmd
                    -- Go to login page after downloading PDF
                    (Route.replaceUrl guest.shared.navKey (Route.Login Nothing))

        CompletedSignUp (Err _) ->
            UR.init { model | serverError = Just "Server error" }

        CompletedLoadInvite (Ok (Just invitation)) ->
            UR.init
                { model
                    | status =
                        case model.status of
                            LoadedCountry country ->
                                LoadedAll invitation country

                            NotFound ->
                                NotFound

                            _ ->
                                LoadedInvite invitation
                }

        CompletedLoadInvite (Ok Nothing) ->
            UR.init { model | status = NotFound }

        CompletedLoadInvite (Err error) ->
            { model | status = FailedInvite error }
                |> UR.init
                |> UR.logGraphqlError msg error

        CompletedLoadCountry (Ok (Just country)) ->
            { model
                | status =
                    case model.status of
                        LoadedInvite invitation ->
                            LoadedAll invitation country

                        NotFound ->
                            NotFound

                        _ ->
                            LoadedCountry country
            }
                |> UR.init

        CompletedLoadCountry (Ok Nothing) ->
            UR.init { model | status = NotFound }

        CompletedLoadCountry (Err error) ->
            { model | status = FailedCountry error }
                |> UR.init
                |> UR.logGraphqlError msg error


type alias SignUpResponse =
    { reason : String
    , status : SignUpStatus.SignUpStatus
    }


formTypeToCmd : Shared -> String -> FormType -> Cmd Msg
formTypeToCmd shared key formType =
    let
        cmd obj =
            Api.Graphql.mutation shared
                (Mutation.signUp
                    { input =
                        InputObject.buildSignUpInput
                            obj
                            (\x -> x)
                    }
                    (Graphql.SelectionSet.succeed SignUpResponse
                        |> with Cambiatus.Object.SignUp.reason
                        |> with Cambiatus.Object.SignUp.status
                    )
                )
                CompletedSignUp
    in
    case formType of
        Juridical form ->
            cmd { account = form.account, email = form.email, name = form.name, publicKey = key }

        Natural form ->
            cmd { account = form.account, email = form.email, name = form.name, publicKey = key }

        Default form ->
            cmd { account = form.account, email = form.email, name = form.name, publicKey = key }

        None ->
            Cmd.none



--
-- Model functions
--


jsAddressToMsg : List String -> Value -> Maybe Msg
jsAddressToMsg addr val =
    case addr of
        "ValidateForm" :: [] ->
            Decode.decodeValue decodeAvailabilityResponse val
                |> Result.map GotAccountAvailabilityResponse
                |> Result.toMaybe

        "GotAccountAvailabilityResponse" :: _ ->
            Decode.decodeValue (Decode.field "data" decodeAccount) val
                |> AccountGenerated
                |> Just

        "PdfDownloaded" :: _ ->
            Just PdfDownloaded

        "CopiedToClipboard" :: _ ->
            Just CopiedToClipboard

        _ ->
            Nothing


msgToString : Msg -> List String
msgToString msg =
    case msg of
        FormMsg _ ->
            [ "FormMsg" ]

        ValidateForm _ ->
            [ "ValidateForm" ]

        GotAccountAvailabilityResponse _ ->
            [ "GotAccountAvailabilityResponse" ]

        AccountGenerated r ->
            [ "AccountGenerated", UR.resultToString r ]

        AgreedToSave12Words _ ->
            [ "AgreedToSave12Words" ]

        CopyToClipboard _ ->
            [ "CopyToClipboard" ]

        CopiedToClipboard ->
            [ "CopiedToClipboard" ]

        DownloadPdf _ ->
            [ "DownloadPdf" ]

        PdfDownloaded ->
            [ "PdfDownloaded" ]

        CompletedLoadInvite _ ->
            [ "CompletedLoadInvite" ]

        AccountTypeSelected _ ->
            [ "AccountTypeSelected" ]

        DefaultFormMsg1 _ ->
            [ "DefaultFormMsg1" ]

        CompletedSignUp _ ->
            [ "CompletedSignUp" ]

        CompletedLoadCountry _ ->
            [ "CompletedLoadCountry" ]
