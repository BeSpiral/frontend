module Profile.EditKycForm exposing
    ( CostaRicaDoc(..)
    , Doc
    , KycFormField(..)
    , Model
    , Msg(..)
    , initKycForm
    , kycValidator
    , update
    , valToDoc
    , view
    )

import Api.Graphql
import Graphql.Http
import Html exposing (Html, button, div, form, input, label, option, p, select, text)
import Html.Attributes exposing (attribute, class, maxlength, placeholder, selected, type_, value)
import Html.Events exposing (onInput, onSubmit)
import Kyc exposing (ProfileKyc)
import Kyc.CostaRica.CedulaDeIdentidad as CedulaDeIdentidad
import Kyc.CostaRica.Dimex as Dimex
import Kyc.CostaRica.Nite as Nite
import Kyc.CostaRica.Phone as Phone
import Page exposing (Session(..))
import Profile
import Session.LoggedIn as LoggedIn exposing (External)
import Session.Shared exposing (Translators)
import UpdateResult as UR
import Validate exposing (Validator, ifBlank, validate)


type Msg
    = DocumentTypeChanged String
    | DocumentNumberEntered String
    | PhoneNumberEntered String
    | KycFormSubmitted Model


type CostaRicaDoc
    = CedulaDoc
    | DimexDoc
    | NiteDoc


type alias Doc =
    { docType : CostaRicaDoc
    , isValid : String -> Bool
    , title : String
    , value : String
    , maxLength : Int
    , pattern : String
    }


type KycFormField
    = DocumentNumber
    | PhoneNumber


type alias Model =
    { document : Doc
    , documentNumber : String
    , phoneNumber : String
    , problems : List ( KycFormField, String )
    , serverError : Maybe String
    }


kycValidator : (String -> Bool) -> Validator ( KycFormField, String ) Model
kycValidator isValid =
    let
        ifInvalidNumber subjectToString error =
            Validate.ifFalse (\subject -> isValid (subjectToString subject)) error

        ifInvalidPhoneNumber subjectToString error =
            Validate.ifFalse (\subject -> Phone.isValid (subjectToString subject)) error
    in
    Validate.all
        [ Validate.firstError
            [ ifBlank .documentNumber ( DocumentNumber, "Please, enter a document number." )
            , ifInvalidNumber .documentNumber ( DocumentNumber, "Please, use a valid document number." )
            ]
        , Validate.firstError
            [ ifBlank .phoneNumber ( PhoneNumber, "Please, enter a phone number." )
            , ifInvalidPhoneNumber .phoneNumber ( PhoneNumber, "Please, use a valid phone number." )
            ]
        ]


initKycForm : Model
initKycForm =
    { document = valToDoc "Cedula"
    , documentNumber = ""
    , phoneNumber = ""
    , problems = []
    , serverError = Nothing
    }


valToDoc : String -> Doc
valToDoc v =
    case v of
        "DIMEX" ->
            { docType = DimexDoc
            , isValid = Dimex.isValid
            , title = "DIMEX Number"
            , value = "dimex"
            , maxLength = 12
            , pattern = "XXXXXXXXXXX or XXXXXXXXXXXX"
            }

        "NITE" ->
            { docType = NiteDoc
            , isValid = Nite.isValid
            , title = "NITE Number"
            , value = "nite"
            , maxLength = 10
            , pattern = "XXXXXXXXXX"
            }

        _ ->
            { docType = CedulaDoc
            , isValid = CedulaDeIdentidad.isValid
            , title = "Cédula de identidad"
            , value = "cedula_de_identidad"
            , maxLength = 11
            , pattern = "X-XXXX-XXXX"
            }


view : Translators -> Model -> Html Msg
view { t } ({ document, documentNumber, phoneNumber, problems, serverError } as kycForm) =
    let
        { docType, pattern, maxLength, isValid, title } =
            document

        showProblem field =
            case List.filter (\( f, _ ) -> f == field) problems of
                h :: _ ->
                    div [ class "form-error" ]
                        [ text (Tuple.second h) ]

                [] ->
                    text ""
    in
    div [ class "md:max-w-sm md:mx-auto mt-6" ]
        [ p []
            [ text "This community requires it's members to have some more information. Please, fill these fields below." ]
        , p [ class "mt-2 mb-6" ]
            [ text "You can always remove this information from your profile if you decide to do so." ]
        , form
            [ onSubmit (KycFormSubmitted kycForm) ]
            [ div [ class "form-field mb-6" ]
                [ case serverError of
                    Just e ->
                        div [ class "bg-red border-lg rounded p-4 mt-2 text-white mb-6" ] [ text e ]

                    Nothing ->
                        text ""
                , label [ class "input-label block" ]
                    [ text "document type"
                    ]
                , select
                    [ onInput DocumentTypeChanged
                    , class "form-select"
                    ]
                    [ option
                        [ value "Cedula"
                        , selected (docType == CedulaDoc)
                        ]
                        [ text "Cedula de identidad" ]
                    , option
                        [ value "DIMEX"
                        , selected (docType == DimexDoc)
                        ]
                        [ text "DIMEX number" ]
                    , option
                        [ value "NITE"
                        , selected (docType == NiteDoc)
                        ]
                        [ text "NITE number" ]
                    ]
                ]
            , div [ class "form-field mb-6" ]
                [ label [ class "input-label block" ]
                    [ text title ]
                , input
                    [ type_ "text"
                    , class "form-input"
                    , attribute "inputmode" "numeric"
                    , onInput DocumentNumberEntered
                    , value documentNumber
                    , maxlength maxLength
                    , placeholder pattern
                    ]
                    []
                , showProblem DocumentNumber
                ]
            , div [ class "form-field mb-10" ]
                [ label [ class "input-label block" ]
                    [ text "phone number" ]
                , input
                    [ type_ "tel"
                    , class "form-input"
                    , value phoneNumber
                    , onInput PhoneNumberEntered
                    , maxlength 9
                    , placeholder "XXXX-XXXX"
                    ]
                    []
                , showProblem PhoneNumber
                ]
            , div []
                [ button
                    [ class "button w-full button-primary" ]
                    [ text "Save and Join" ]
                ]
            ]
        ]


type alias UpdateResult =
    UR.UpdateResult Model Msg (External Msg)


update : Model -> Msg -> Model
update model msg =
    case msg of
        DocumentTypeChanged val ->
            { model
                | document = valToDoc val
                , documentNumber = ""
                , problems = []
            }

        DocumentNumberEntered n ->
            let
                trim : Int -> String -> String -> String
                trim desiredLength oldNum newNum =
                    let
                        corrected =
                            if String.all Char.isDigit newNum then
                                newNum

                            else
                                oldNum
                    in
                    if String.length corrected > desiredLength then
                        String.slice 0 desiredLength corrected

                    else
                        corrected

                trimmedNumber =
                    if String.startsWith "0" n then
                        model.documentNumber

                    else
                        trim model.document.maxLength model.documentNumber n
            in
            { model | documentNumber = trimmedNumber }

        PhoneNumberEntered p ->
            { model | phoneNumber = p }

        KycFormSubmitted form ->
            let
                errors =
                    case validate (kycValidator form.document.isValid) form of
                        Ok _ ->
                            []

                        Err errs ->
                            errs

                newForm =
                    { form | problems = errors }
            in
            newForm
