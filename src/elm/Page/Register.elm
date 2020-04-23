module Page.Register exposing (Model, Msg, init, jsAddressToMsg, msgToString, subscriptions, update, view)

import Api
import Auth exposing (viewFieldLabel)
import Browser.Dom as Dom
import Browser.Events
import Char
import Eos.Account as Eos
import Graphql.Http
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (keyCode, on, onClick, onInput, onSubmit)
import Http
import I18Next exposing (t)
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode
import List.Extra as LE
import Profile exposing (Profile)
import Route
import Session.Guest as Guest exposing (External(..))
import Session.Shared exposing (Shared)
import Task
import UpdateResult as UR
import Utils exposing (..)
import Validate exposing (Validator, ifBlank, ifFalse, ifInvalidEmail, ifTrue, validate)



-- INIT


init : Guest.Model -> ( Model, Cmd Msg )
init guest =
    ( initModel guest
    , Cmd.none
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.map PressedEnter (Browser.Events.onKeyDown decodeEnterKeyDown)



-- MODEL


type alias Model =
    { accountKeys : Maybe AccountKeys
    , isLoading : Bool
    , isCheckingAccount : Bool
    , form : Form
    , accountGenerated : Bool
    , problems : List Problem
    }


initModel : Guest.Model -> Model
initModel _ =
    { accountKeys = Nothing
    , isLoading = False
    , isCheckingAccount = False
    , form = initForm
    , accountGenerated = False
    , problems = []
    }



---- FORM


type alias Form =
    { username : String
    , email : String
    , account : String
    }


initForm : Form
initForm =
    { username = ""
    , email = ""
    , account = ""
    }


type Problem
    = InvalidEntry ValidatedField String
    | ServerError String


type ValidatedField
    = Username
    | Email
    | Account


type ValidationError
    = AccountTooShort
    | AccountTooLong
    | AccountAlreadyExists
    | AccountInvalidChars



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



-- VIEW


view : Guest.Model -> Model -> Html Msg
view guest model =
    let
        shared =
            guest.shared

        t str =
            I18Next.t guest.shared.translations str

        text_ s =
            text (t s)

        isDisabled =
            model.isLoading || model.isCheckingAccount

        tr r_id replaces =
            I18Next.tr shared.translations I18Next.Curly r_id replaces

        name =
            accName model
    in
    if model.accountGenerated then
        div [ class "main__register__details" ]
            [ div [ class "register__congrats" ]
                [ div [ class "register__woman" ] []
                , p [ class "congrats__message" ]
                    [ span [] [ text_ "register.account_created.congrats" ]
                    , span [] [ text_ "register.account_created.account" ]
                    , span [] [ text_ "register.account_created.created" ]
                    ]
                , div [ class "register__dog" ] []
                ]
            , div [ class "register__welcome" ]
                [ text (tr "register.account_created.welcome_message" [ ( "username", name ) ]) ]
            , div [ class "register__keys" ]
                [ p [ class "key__title" ] [ text_ "register.account_created.twelve_words" ]
                , p [ class "key", id "12__words" ] [ text (words model) ]
                , p [ class "key__title" ] [ text_ "register.account_created.private_key" ]
                , p [ class "key", id "p__key" ] [ text (privateKey model) ]
                ]
            , div [ class "register__instructions" ]
                [ p [] [ text_ "register.account_created.instructions" ] ]
            , button
                [ onClick DownloadPdf
                , class "btn btn__register"
                ]
                [ text_ "register.account_created.download" ]
            , div [ class "register__footer" ]
                [ span [] [ text_ "register.account_created.instructions" ] ]
            ]

    else
        Html.form
            [ onSubmit ValidateForm
            ]
            [ div [ class "min-w-full md:min-w-0 md:mx-auto px-4" ]
                [ p [ class "text-white" ]
                    [ text "Step 1 of 2 / Basic informations" ]
                , p
                    [ class "text-grey" ]
                    [ text_ "register.form.title" ]
                , viewServerErrors model.problems
                , viewField shared
                    (Field
                        "register.form.name"
                        isDisabled
                        "name"
                        Username
                    )
                    (identity EnteredUsername)
                    [ maxlength 255 ]
                    model.problems
                , viewField shared
                    (Field
                        "register.form.account"
                        isDisabled
                        "account"
                        Account
                    )
                    (identity EnteredAccount)
                    Eos.nameValidationAttrs
                    model.problems
                , viewField shared
                    (Field
                        "register.form.email"
                        isDisabled
                        "email"
                        Email
                    )
                    (identity EnteredEmail)
                    [ type_ "email" ]
                    model.problems
                , p [ class "text-white my-10" ]
                    [ text_ "register.login"
                    , a [ Route.href (Route.Login Nothing), class "text-orange-300 underline" ] [ text_ "register.authLink" ]
                    ]
                , button
                    [ class "button button-primary min-w-full"
                    , type_ "submit"
                    , disabled isDisabled
                    ]
                    [ if model.isCheckingAccount then
                        text_ "register.form.checkingAvailability"

                      else
                        text_ "register.form.button"
                    ]
                ]
            ]


viewServerErrors : List Problem -> Html msg
viewServerErrors problems =
    let
        errorList =
            problems
                |> List.filterMap
                    (\p ->
                        case p of
                            ServerError e ->
                                Just (li [ class "field__error" ] [ text e ])

                            _ ->
                                Nothing
                    )
    in
    ul [] errorList


type alias Field =
    { translationSuffix : String
    , isDisabled : Bool
    , id_ : String
    , validation : ValidatedField
    }


viewField : Shared -> Field -> (String -> FormInputMsg) -> List (Attribute FormInputMsg) -> List Problem -> Html Msg
viewField ({ translations } as shared) { translationSuffix, isDisabled, id_, validation } msg extraAttrs problems =
    let
        errors =
            List.map (\err -> viewFieldProblem validation err) problems

        fProbs =
            List.filter
                (\p ->
                    case p of
                        InvalidEntry v _ ->
                            validation == v

                        _ ->
                            False
                )
                problems

        errorClass =
            case fProbs of
                [] ->
                    ""

                _ ->
                    " errored__field"
    in
    div [ class "form-field" ]
        [ viewFieldLabel shared translationSuffix id_ Nothing
        , input
            ([ id id_
             , onInput msg
             , class ("input" ++ errorClass)
             , disabled isDisabled
             , required True
             , placeholder (t translations (translationSuffix ++ ".placeholder"))
             ]
                ++ extraAttrs
            )
            []
            |> Html.map UpdateForm
        , ul [] errors
        ]


viewFieldProblem : ValidatedField -> Problem -> Html msg
viewFieldProblem field problem =
    case problem of
        ServerError _ ->
            text ""

        InvalidEntry f str ->
            if f == field then
                li [ class "field__error" ] [ text str ]

            else
                text ""


validationErrorToString : Shared -> ValidationError -> String
validationErrorToString shared error =
    let
        t s =
            I18Next.t shared.translations s

        tr str values =
            I18Next.tr shared.translations I18Next.Curly str values
    in
    case error of
        AccountTooShort ->
            tr "error.tooShort" [ ( "minLength", "12" ) ]

        AccountTooLong ->
            tr "error.tooLong" [ ( "maxLength", "12" ) ]

        AccountAlreadyExists ->
            t "error.alreadyTaken"

        AccountInvalidChars ->
            t "register.form.accountCharError"


accName : Model -> String
accName model =
    case model.accountKeys of
        Just keys ->
            Eos.nameToString keys.accountName

        Nothing ->
            ""


words : Model -> String
words model =
    case model.accountKeys of
        Just keys ->
            keys.words

        Nothing ->
            ""


privateKey : Model -> String
privateKey model =
    case model.accountKeys of
        Just keys ->
            keys.privateKey

        Nothing ->
            ""



-- UPDATE


type alias UpdateResult =
    UR.UpdateResult Model Msg External


type Msg
    = UpdateForm FormInputMsg
    | Ignored
    | ValidateForm
    | GotAccountAvailabilityResponse Bool
    | AccountGenerated (Result Decode.Error AccountKeys)
    | CompletedCreateProfile AccountKeys (Result Http.Error Profile)
    | CompletedLoadProfile AccountKeys (Result Http.Error Profile)
    | DownloadPdf
    | PdfDownloaded
    | PressedEnter Bool


update : Maybe String -> Msg -> Model -> Guest.Model -> UpdateResult
update maybeInvitation msg model guest =
    let
        shared =
            guest.shared
    in
    case msg of
        Ignored ->
            model
                |> UR.init

        UpdateForm subMsg ->
            updateForm subMsg shared model
                |> UR.init

        ValidateForm ->
            let
                allProbs =
                    model.problems
            in
            case allProbs of
                [] ->
                    { model | isCheckingAccount = True }
                        |> UR.init
                        |> UR.addPort
                            { responseAddress = ValidateForm
                            , responseData = Encode.null
                            , data =
                                Encode.object
                                    [ ( "name", Encode.string "checkAccountAvailability" )
                                    , ( "accountName", Encode.string model.form.account )
                                    ]
                            }

                _ ->
                    { model | problems = allProbs }
                        |> UR.init

        GotAccountAvailabilityResponse isAvailable ->
            if isAvailable then
                UR.init
                    { model
                        | isLoading = True
                        , problems = []
                        , isCheckingAccount = False
                    }
                    |> UR.addPort
                        { responseAddress = GotAccountAvailabilityResponse False
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
                                , ( "account", Encode.string model.form.account )
                                ]
                        }

            else
                let
                    fieldError =
                        validationErrorToString shared AccountAlreadyExists
                            |> InvalidEntry Account
                in
                UR.init
                    { model
                        | problems = fieldError :: model.problems
                        , isCheckingAccount = False
                    }

        AccountGenerated (Ok accountKeys) ->
            UR.init
                { model
                    | isLoading = True
                    , accountKeys = Just accountKeys
                    , form = initForm
                }
                |> UR.addCmd
                    (case maybeInvitation of
                        Nothing ->
                            Api.signUp guest.shared
                                { name = model.form.username
                                , email = model.form.email
                                , account = accountKeys.accountName
                                , invitationId = maybeInvitation
                                }
                                (CompletedCreateProfile accountKeys)

                        Just _ ->
                            Api.signUpWithInvitation guest.shared
                                { name = model.form.username
                                , email = model.form.email
                                , account = accountKeys.accountName
                                , invitationId = maybeInvitation
                                }
                                (CompletedCreateProfile accountKeys)
                    )

        AccountGenerated (Err v) ->
            UR.init
                { model
                    | isLoading = False
                    , problems = ServerError "The server acted in an unexpected way" :: model.problems
                }
                |> UR.logDecodeError msg v

        CompletedCreateProfile _ (Ok _) ->
            { model | accountGenerated = True }
                |> UR.init
                |> UR.addPort
                    { responseAddress = Ignored
                    , responseData = Encode.null
                    , data =
                        Encode.object
                            [ ( "name", Encode.string "hideFooter" ) ]
                    }

        CompletedCreateProfile _ (Err err) ->
            { model | problems = ServerError "Auth failed" :: model.problems }
                |> UR.init
                |> UR.logHttpError msg err

        CompletedLoadProfile _ (Ok profile) ->
            UR.init model
                |> UR.addCmd (Route.replaceUrl guest.shared.navKey Route.Dashboard)
                |> UR.addExt (UpdatedGuest { guest | profile = Just profile })

        CompletedLoadProfile _ (Err err) ->
            { model | problems = ServerError "Auth failed" :: model.problems }
                |> UR.init
                |> UR.logHttpError msg err

        DownloadPdf ->
            model
                |> UR.init
                |> UR.addPort
                    { responseAddress = PdfDownloaded
                    , responseData = Encode.null
                    , data =
                        Encode.object
                            [ ( "name", Encode.string "printAuthPdf" ) ]
                    }

        PdfDownloaded ->
            case model.accountKeys of
                Nothing ->
                    model
                        |> UR.init

                Just keys ->
                    model
                        |> UR.init
                        |> UR.addCmd
                            --(CompletedLoadProfile keys
                            --    |> Api.signIn guest.shared keys.accountName
                            --)
                            -- Go to login page after downloading PDF
                            (Route.replaceUrl guest.shared.navKey (Route.Login Nothing))

        PressedEnter val ->
            if val then
                UR.init model
                    |> UR.addCmd
                        (Task.succeed ValidateForm
                            |> Task.perform identity
                        )

            else
                UR.init model



--
-- Model functions
--


type FormInputMsg
    = EnteredUsername String
    | EnteredEmail String
    | EnteredAccount String


updateForm : FormInputMsg -> Shared -> Model -> Model
updateForm msg shared ({ form } as model) =
    let
        vErrorString verror =
            validationErrorToString shared verror

        fieldProbs validator val =
            case validate validator val of
                Ok _ ->
                    []

                Err errs ->
                    errs

        otherProbs validationField probs =
            probs
                |> List.filter
                    (\p ->
                        case p of
                            InvalidEntry v _ ->
                                v /= validationField

                            _ ->
                                True
                    )
    in
    case msg of
        EnteredUsername str ->
            let
                newProblems =
                    otherProbs Username model.problems

                nameValidator : Validator Problem String
                nameValidator =
                    Validate.firstError
                        [ ifBlank identity (InvalidEntry Username "Name can't be blank") ]

                nameProbs =
                    fieldProbs nameValidator str

                newForm =
                    { form | username = str }
            in
            { model
                | form = newForm
                , problems = newProblems ++ nameProbs
            }

        EnteredEmail str ->
            let
                newProblems =
                    otherProbs Email model.problems

                emailValidator : Validator Problem String
                emailValidator =
                    Validate.firstError
                        [ ifBlank identity (InvalidEntry Email "Email can't be blank")
                        , ifInvalidEmail identity (\_ -> InvalidEntry Email "Email has to be valid email")
                        ]

                emailProbs =
                    fieldProbs emailValidator str

                newForm =
                    { form | email = str }
            in
            { model
                | form = newForm
                , problems = newProblems ++ emailProbs
            }

        EnteredAccount str ->
            let
                newProblems =
                    otherProbs Account model.problems

                isLowerThan6 : Char -> Bool
                isLowerThan6 c =
                    let
                        charInt : Int
                        charInt =
                            c
                                |> String.fromChar
                                |> String.toInt
                                |> Maybe.withDefault 0
                    in
                    compare charInt 6 == Basics.LT

                isValidAlphaNum : Char -> Bool
                isValidAlphaNum c =
                    (Char.isUpper c || Char.isLower c || Char.isDigit c) && isLowerThan6 c

                accountValidator : Validator Problem String
                accountValidator =
                    Validate.firstError
                        [ ifBlank identity (InvalidEntry Account "Account is required")
                        , ifTrue (\accStr -> String.length accStr < 12) (InvalidEntry Account (vErrorString AccountTooShort))
                        , ifTrue (\accStr -> String.length accStr > 12) (InvalidEntry Account (vErrorString AccountTooLong))
                        , ifFalse (\accStr -> String.all isValidAlphaNum accStr) (InvalidEntry Account (vErrorString AccountInvalidChars))
                        ]

                accProbs =
                    fieldProbs accountValidator str

                newForm =
                    { form | account = str |> String.toLower }
            in
            { model
                | form = newForm
                , problems = newProblems ++ accProbs
            }


asPinString : List (Maybe String) -> String
asPinString entered =
    entered
        |> List.map (\a -> Maybe.withDefault "" a)
        |> List.foldl (\a b -> a ++ b) ""


jsAddressToMsg : List String -> Value -> Maybe Msg
jsAddressToMsg addr val =
    case addr of
        "ValidateForm" :: [] ->
            Decode.decodeValue
                (Decode.field "isAvailable" Decode.bool)
                val
                |> Result.map GotAccountAvailabilityResponse
                |> Result.toMaybe

        "GotAccountAvailabilityResponse" :: _ ->
            Decode.decodeValue (Decode.field "data" decodeAccount) val
                |> AccountGenerated
                |> Just

        "PdfDownloaded" :: _ ->
            Just PdfDownloaded

        _ ->
            Nothing


msgToString : Msg -> List String
msgToString msg =
    case msg of
        Ignored ->
            [ "Ignored" ]

        UpdateForm _ ->
            [ "UpdateForm" ]

        ValidateForm ->
            [ "ValidateForm" ]

        GotAccountAvailabilityResponse _ ->
            [ "GotAccountAvailabilityResponse" ]

        AccountGenerated r ->
            [ "AccountGenerated", UR.resultToString r ]

        CompletedCreateProfile _ r ->
            [ "CompletedCreateProfile", UR.resultToString r ]

        CompletedLoadProfile _ r ->
            [ "CompletedLoadProfile", UR.resultToString r ]

        DownloadPdf ->
            [ "DownloadPdf" ]

        PdfDownloaded ->
            [ "PdfDownloaded" ]

        PressedEnter _ ->
            [ "PressedEnter" ]
