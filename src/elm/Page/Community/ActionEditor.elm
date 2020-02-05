module Page.Community.ActionEditor exposing (Model, Msg, initEdit, initNew, jsAddressToMsg, msgToString, update, view)

import Account exposing (Profile)
import Api.Graphql
import Avatar exposing (Avatar)
import Bespiral.Scalar exposing (DateTime(..))
import Community exposing (Community)
import DataValidator exposing (Validator, getInput, greaterThan, greaterThanOrEqual, hasErrors, listErrors, longerThan, newValidator, oneOf, shorterThan, updateInput, validate)
import Eos exposing (Symbol)
import Eos.Account as Eos
import Graphql.Http
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onCheck, onClick, onInput, targetValue)
import I18Next exposing (t)
import Icons
import Json.Decode as Json exposing (Value)
import Json.Encode as Encode
import MaskedInput.Text as MaskedDate
import Page
import Route
import Select
import Session.LoggedIn as LoggedIn exposing (External(..))
import Session.Shared exposing (Shared)
import Simple.Fuzzy
import Time exposing (Posix)
import UpdateResult as UR
import Utils



-- INIT


initNew : LoggedIn.Model -> Symbol -> Int -> ( Model, Cmd Msg )
initNew loggedIn symbol objId =
    ( { status = Loading
      , communityId = symbol
      , objectiveId = objId
      , actionId = Nothing
      , form = initForm
      , multiSelectState = Select.newState ""
      }
    , Api.Graphql.query loggedIn.shared (Community.communityQuery symbol) CompletedCommunityLoad
    )


initEdit : LoggedIn.Model -> Symbol -> Int -> Int -> ( Model, Cmd Msg )
initEdit loggedIn symbol objectiveId actionId =
    ( { status = Loading
      , communityId = symbol
      , objectiveId = objectiveId
      , actionId = Just actionId
      , form = initForm
      , multiSelectState = Select.newState ""
      }
    , Api.Graphql.query loggedIn.shared (Community.communityQuery symbol) CompletedCommunityLoad
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- MODEL


type alias Model =
    { status : Status
    , communityId : Symbol
    , objectiveId : Int
    , actionId : Maybe Int
    , form : Form
    , multiSelectState : Select.State
    }


type Status
    = Loading
    | Loaded Community
      -- Errors
    | LoadFailed (Graphql.Http.Error (Maybe Community))
    | NotFound
    | Unauthorized


type ActionValidation
    = NoValidation
    | Validations (Maybe (Validator String)) (Maybe (Validator Int)) -- Date validation, usage validate


type Verification
    = Automatic
    | Manual (List Profile) (Validator Float) (Validator Int) -- Manual: users list, verification reward and min votes


type SaveStatus
    = NotAsked
    | Saving
    | Saved
    | Failed


type alias Form =
    { description : Validator String
    , reward : Validator Float
    , validation : ActionValidation
    , verification : Verification
    , deadlineState : MaskedDate.State
    , saveStatus : SaveStatus
    }


initForm : Form
initForm =
    { description = defaultDescription
    , reward = defaultReward
    , validation = NoValidation
    , verification = Automatic
    , deadlineState = MaskedDate.initialState
    , saveStatus = NotAsked
    }


editForm : Form -> Community.Action -> Form
editForm form action =
    { form
        | description = updateInput action.description form.description
        , reward = updateInput action.reward form.reward
    }


defaultDescription : Validator String
defaultDescription =
    []
        |> longerThan 10
        |> shorterThan 256
        |> newValidator "" (\v -> Just v) True


defaultReward : Validator Float
defaultReward =
    []
        |> greaterThanOrEqual 1.0
        |> newValidator 0.0 (\s -> Just "0.0") True


defaultUsagesValidator : Validator Int
defaultUsagesValidator =
    []
        |> greaterThan 0
        |> newValidator 0 (\s -> Just "0") True


defaultVerificationReward : Validator Float
defaultVerificationReward =
    []
        |> greaterThanOrEqual 1.0
        |> newValidator 0.0 (\s -> Just "0,0") False


defaultMinVotes : Validator Int
defaultMinVotes =
    []
        |> greaterThanOrEqual 2
        |> newValidator 0 (\s -> Just "0") False


validateForm : Form -> Form
validateForm form =
    let
        validation =
            case form.validation of
                NoValidation ->
                    NoValidation

                Validations (Just dateValidation) (Just usageValidation) ->
                    Validations (Just (validate dateValidation)) (Just (validate usageValidation))

                Validations (Just dateValidation) Nothing ->
                    Validations (Just (validate dateValidation)) Nothing

                Validations Nothing (Just usageValidation) ->
                    Validations Nothing (Just (validate usageValidation))

                Validations Nothing Nothing ->
                    NoValidation

        verification =
            case form.verification of
                Automatic ->
                    Automatic

                Manual profiles verificationReward minVotes ->
                    Manual profiles (validate verificationReward) (validate minVotes)
    in
    { form
        | description = validate form.description
        , reward = validate form.reward
        , validation = validation
        , verification = verification
    }


isFormValid : Form -> Bool
isFormValid form =
    hasErrors form.description
        || hasErrors form.reward
        |> not


hasDateValidation : ActionValidation -> Bool
hasDateValidation validation =
    case validation of
        NoValidation ->
            False

        Validations maybeDate _ ->
            case maybeDate of
                Just _ ->
                    True

                Nothing ->
                    False


hasUnitValidation : ActionValidation -> Bool
hasUnitValidation validation =
    case validation of
        NoValidation ->
            False

        Validations _ maybeUnit ->
            case maybeUnit of
                Just _ ->
                    True

                Nothing ->
                    False



-- UPDATE


type alias UpdateResult =
    UR.UpdateResult Model Msg (External Msg)


type Msg
    = CompletedCommunityLoad (Result (Graphql.Http.Error (Maybe Community)) (Maybe Community))
    | OnSelectVerifier (Maybe Profile)
    | OnRemoveVerifier Profile
    | SelectMsg (Select.Msg Profile)
    | EnteredDescription String
    | EnteredReward String
    | EnteredDeadline String
    | DeadlineChanged MaskedDate.State
    | EnteredUsages String
    | EnteredVerifierReward String
    | EnteredMinVotes String
      -- | SubmittedData
    | ToggleValidity Bool
    | ToggleDeadline Bool
    | ToggleUsages Bool
    | SetVerification String
    | ValidateForm
    | ValidateDeadline
    | GotInvalidDate
    | SaveAction (Result Value String)
    | GotSaveAction (Result Value String)


update : Msg -> Model -> LoggedIn.Model -> UpdateResult
update msg model loggedIn =
    let
        shared =
            loggedIn.shared
    in
    case msg of
        CompletedCommunityLoad (Err err) ->
            { model | status = LoadFailed err }
                |> UR.init
                |> UR.logGraphqlError msg err

        CompletedCommunityLoad (Ok c) ->
            case c of
                Just community ->
                    if community.creator == loggedIn.accountName then
                        -- Check the action belongs to the objective
                        let
                            maybeObjective =
                                List.filterMap
                                    (\o ->
                                        if o.id == model.objectiveId then
                                            Just o

                                        else
                                            Nothing
                                    )
                                    community.objectives
                                    |> List.head
                        in
                        case maybeObjective of
                            Just objective ->
                                case model.actionId of
                                    Just actionId ->
                                        -- Edit form
                                        let
                                            maybeAction =
                                                List.filterMap
                                                    (\a ->
                                                        if a.id == actionId then
                                                            Just a

                                                        else
                                                            Nothing
                                                    )
                                                    objective.actions
                                                    |> List.head
                                        in
                                        case maybeAction of
                                            Just action ->
                                                { model
                                                    | status = Loaded community
                                                    , form = editForm model.form action
                                                }
                                                    |> UR.init

                                            Nothing ->
                                                { model | status = NotFound }
                                                    |> UR.init

                                    Nothing ->
                                        -- New form
                                        { model
                                            | status = Loaded community
                                            , form = initForm
                                        }
                                            |> UR.init

                            Nothing ->
                                { model | status = NotFound }
                                    |> UR.init

                    else
                        { model | status = Unauthorized }
                            |> UR.init

                Nothing ->
                    { model | status = NotFound }
                        |> UR.init
                        |> UR.logImpossible msg []

        OnSelectVerifier maybeProfile ->
            let
                oldForm =
                    model.form
            in
            case model.form.verification of
                Automatic ->
                    model
                        |> UR.init

                Manual selectedVerifiers verificationReward minVotes ->
                    { model
                        | form =
                            { oldForm
                                | verification =
                                    Manual
                                        (maybeProfile
                                            |> Maybe.map (List.singleton >> List.append selectedVerifiers)
                                            |> Maybe.withDefault selectedVerifiers
                                        )
                                        verificationReward
                                        minVotes
                            }
                    }
                        |> UR.init

        OnRemoveVerifier profile ->
            let
                oldForm =
                    model.form

                verification =
                    case model.form.verification of
                        Automatic ->
                            model.form.verification

                        Manual selectedVerifiers a b ->
                            Manual (List.filter (\currVerifier -> currVerifier.accountName /= profile.accountName) selectedVerifiers) a b
            in
            { model | form = { oldForm | verification = verification } }
                |> UR.init

        SelectMsg subMsg ->
            let
                ( updated, cmd ) =
                    Select.update (selectConfig loggedIn.shared False) subMsg model.multiSelectState
            in
            { model | multiSelectState = updated }
                |> UR.init
                |> UR.addCmd cmd

        EnteredDescription val ->
            let
                oldForm =
                    model.form
            in
            { model | form = { oldForm | description = updateInput val model.form.description } }
                |> UR.init

        EnteredReward val ->
            let
                oldForm =
                    model.form

                value =
                    String.toFloat val
                        |> Maybe.withDefault 0.0
            in
            { model | form = { oldForm | reward = updateInput value model.form.reward } }
                |> UR.init

        EnteredDeadline val ->
            let
                oldForm =
                    model.form
            in
            case model.form.validation of
                NoValidation ->
                    model
                        |> UR.init
                        |> UR.logImpossible msg []

                Validations maybeDate usageValidation ->
                    case maybeDate of
                        Just dateValidation ->
                            { model
                                | form =
                                    { oldForm
                                        | validation = Validations (Just (updateInput val dateValidation)) usageValidation
                                    }
                            }
                                |> UR.init

                        Nothing ->
                            model
                                |> UR.init
                                |> UR.logImpossible msg []

        EnteredUsages val ->
            let
                oldForm =
                    model.form

                value =
                    String.toInt val
                        |> Maybe.withDefault 0
            in
            case model.form.validation of
                NoValidation ->
                    model
                        |> UR.init
                        |> UR.logImpossible msg []

                Validations maybeDate maybeUsage ->
                    case maybeUsage of
                        Just usageValidation ->
                            { model
                                | form =
                                    { oldForm
                                        | validation = Validations maybeDate (Just (updateInput value usageValidation))
                                    }
                            }
                                |> UR.init

                        Nothing ->
                            model
                                |> UR.init
                                |> UR.logImpossible msg []

        EnteredVerifierReward val ->
            let
                oldForm =
                    model.form

                value =
                    String.toFloat val
                        |> Maybe.withDefault 0.0
            in
            case model.form.verification of
                Automatic ->
                    model
                        |> UR.init
                        |> UR.logImpossible msg []

                Manual listProfile verifierReward minVotes ->
                    { model | form = { oldForm | verification = Manual listProfile (updateInput value verifierReward) minVotes } }
                        |> UR.init

        EnteredMinVotes val ->
            let
                oldForm =
                    model.form

                value =
                    String.toInt val
                        |> Maybe.withDefault 0
            in
            case model.form.verification of
                Automatic ->
                    model
                        |> UR.init
                        |> UR.logImpossible msg []

                Manual listProfile verifierReward minVotes ->
                    { model | form = { oldForm | verification = Manual listProfile verifierReward (updateInput value minVotes) } }
                        |> UR.init

        ValidateForm ->
            { model | form = validateForm model.form }
                |> UR.init

        ValidateDeadline ->
            case model.form.validation of
                NoValidation ->
                    model
                        |> UR.init

                Validations maybeDate _ ->
                    case maybeDate of
                        Just dateValidation ->
                            model
                                |> UR.init
                                |> UR.addPort
                                    { responseAddress = ValidateDeadline
                                    , responseData = Encode.null
                                    , data =
                                        Encode.object
                                            [ ( "name", Encode.string "validateDeadline" )
                                            , ( "deadline"
                                              , Encode.string
                                                    (String.join "/"
                                                        [ String.slice 0 2 (getInput dateValidation) -- month
                                                        , String.slice 2 4 (getInput dateValidation) -- day
                                                        , String.slice 4 8 (getInput dateValidation) -- year
                                                        ]
                                                    )
                                              )
                                            ]
                                    }

                        Nothing ->
                            model
                                |> UR.init

        DeadlineChanged state ->
            let
                oldForm =
                    model.form
            in
            case model.form.validation of
                NoValidation ->
                    model
                        |> UR.init
                        |> UR.logImpossible msg []

                Validations maybeDate usageValidation ->
                    case maybeDate of
                        Just dateValidation ->
                            { model
                                | form =
                                    { oldForm
                                        | deadlineState = state
                                    }
                            }
                                |> UR.init

                        Nothing ->
                            model
                                |> UR.init
                                |> UR.logImpossible msg []

        ToggleValidity bool ->
            model
                |> UR.init

        ToggleDeadline bool ->
            let
                oldForm =
                    model.form

                deadlineValidation =
                    if bool then
                        Just (newValidator "" (\s -> Just "0/0/0") True [])

                    else
                        Nothing

                usagesValidation =
                    case model.form.validation of
                        NoValidation ->
                            Nothing

                        Validations _ maybeUsages ->
                            maybeUsages
            in
            { model
                | form =
                    { oldForm
                        | validation =
                            if deadlineValidation /= Nothing || usagesValidation /= Nothing then
                                Validations deadlineValidation usagesValidation

                            else
                                NoValidation
                    }
            }
                |> UR.init

        ToggleUsages bool ->
            let
                oldForm =
                    model.form

                usagesValidation =
                    if bool then
                        Just defaultUsagesValidator

                    else
                        Nothing

                deadlineValidation =
                    case model.form.validation of
                        NoValidation ->
                            Nothing

                        Validations maybeDate _ ->
                            maybeDate
            in
            { model
                | form =
                    { oldForm
                        | validation =
                            if deadlineValidation /= Nothing || usagesValidation /= Nothing then
                                Validations deadlineValidation usagesValidation

                            else
                                NoValidation
                    }
            }
                |> UR.init

        SetVerification val ->
            let
                oldForm =
                    model.form
            in
            { model
                | form =
                    { oldForm
                        | verification =
                            if val == "automatic" then
                                Automatic

                            else
                                Manual [] defaultVerificationReward defaultMinVotes
                    }
            }
                |> UR.init

        GotInvalidDate ->
            model
                |> UR.init

        SaveAction isoDate ->
            case isoDate of
                Ok date ->
                    let
                        dateInt =
                            if String.length date == 0 then
                                0

                            else
                                Just (DateTime date)
                                    |> Utils.posixDateTime
                                    |> Time.posixToMillis

                        validatorsStr =
                            []
                                |> List.map (\v -> Eos.nameToString v.accountName)
                                |> String.join "-"
                    in
                    -- if LoggedIn.isAuth loggedIn then
                    --     model
                    --         |> UR.init
                    --         |> UR.addPort
                    --             { responseAddress = SaveAction isoDate
                    --             , responseData = Encode.null
                    --             , data =
                    --                 Eos.encodeTransaction
                    --                     { actions =
                    --                         [ { accountName = "bes.cmm"
                    --                           , name = "upsertaction"
                    --                           , authorization =
                    --                                 { actor = loggedIn.accountName
                    --                                 , permissionName = Eos.samplePermission
                    --                                 }
                    --                           , data =
                    --                                 { actionId = 0
                    --                                 , objectiveId = model.objectiveId
                    --                                 , description = model.form.description
                    --                                 , reward = String.fromFloat model.form.reward ++ " " ++ model.form.symbol
                    --                                 , verifier_reward = String.fromFloat model.form.verifierReward ++ " " ++ model.form.symbol
                    --                                 , deadline = dateInt
                    --                                 , usages = model.form.maxUsage
                    --                                 , usagesLeft = model.form.maxUsage
                    --                                 , verifications = model.form.minVotes
                    --                                 , verificationType = model.form.verificationType
                    --                                 , validatorsStr = validatorsStr
                    --                                 , isCompleted = 0
                    --                                 , creator = loggedIn.accountName
                    --                                 }
                    --                                     |> Community.encodeCreateActionAction
                    --                           }
                    --                         ]
                    --                     }
                    --             }
                    -- else
                    model
                        |> UR.init
                        |> UR.addExt
                            (Just (SaveAction isoDate)
                                |> RequiredAuthentication
                            )

                Err _ ->
                    update GotInvalidDate model loggedIn

        GotSaveAction (Ok tId) ->
            model
                |> UR.init
                |> UR.addCmd (Route.replaceUrl loggedIn.shared.navKey (Route.Community model.communityId))

        GotSaveAction (Err val) ->
            model
                |> UR.init
                |> UR.logImpossible msg []



-- VIEW


view : LoggedIn.Model -> Model -> Html Msg
view loggedIn model =
    let
        shared =
            loggedIn.shared

        t s =
            I18Next.t shared.translations s

        text_ s =
            text (t s)
    in
    case model.status of
        Loading ->
            Page.fullPageLoading

        Loaded community ->
            div [ class "bg-white" ]
                [ Page.viewHeader loggedIn (t "community.actions.title") (Route.Objectives model.communityId)
                , viewForm loggedIn community model
                ]

        LoadFailed err ->
            Page.fullPageGraphQLError (t "error.invalidSymbol") err

        NotFound ->
            Page.fullPageNotFound (t "community.actions.form.not_found") ""

        Unauthorized ->
            Page.fullPageNotFound "not authorized" ""


viewForm : LoggedIn.Model -> Community -> Model -> Html Msg
viewForm ({ shared } as loggedIn) community model =
    div [ class "container mx-auto" ]
        [ div [ class "py-6 px-4" ]
            [ viewDescription loggedIn model.form
            , viewReward loggedIn community model.form
            , viewValidations loggedIn model community
            , viewVerifications loggedIn model community
            , div [ class "flex align-center justify-center" ]
                [ button
                    [ class "button button-primary"
                    , onClick ValidateForm
                    ]
                    [ text (t shared.translations "menu.create") ]
                ]
            ]
        ]


viewDescription : LoggedIn.Model -> Form -> Html Msg
viewDescription ({ shared } as loggedIn) form =
    let
        text_ s =
            text (t shared.translations s)
    in
    div [ class "mb-10" ]
        [ span [ class "input-label" ]
            [ text_ "community.actions.form.description_label" ]
        , textarea
            [ class "w-full input rounded-sm"
            , classList [ ( "border-red", hasErrors form.description ) ]
            , rows 5
            , onInput EnteredDescription
            , value (getInput form.description)
            ]
            []
        , viewFieldErrors (listErrors shared.translations form.description)
        ]


viewReward : LoggedIn.Model -> Community -> Form -> Html Msg
viewReward ({ shared } as loggedIn) community form =
    let
        text_ s =
            text (t shared.translations s)
    in
    div [ class "mb-10" ]
        [ span [ class "input-label" ]
            [ text_ "community.actions.form.reward_label" ]
        , div [ class "flex sm:w-2/5 h-12 rounded-sm border border-gray-500" ]
            [ input
                [ class "block w-4/5 border-none px-4 py-3 outline-none"
                , classList [ ( "border-red", hasErrors form.reward ) ]
                , type_ "number"
                , placeholder "0.00"
                , onInput EnteredReward
                , value (getInput form.reward |> String.fromFloat)
                ]
                []
            , span
                [ class "w-1/5 flex text-white items-center justify-center bg-indigo-500 text-body uppercase rounded-r-sm" ]
                [ text (Eos.symbolToString community.symbol) ]
            ]
        , viewFieldErrors (listErrors shared.translations form.reward)
        ]


viewValidations : LoggedIn.Model -> Model -> Community -> Html Msg
viewValidations ({ shared } as loggedIn) model community =
    let
        text_ s =
            text (t shared.translations s)

        dateOptions =
            MaskedDate.defaultOptions EnteredDeadline DeadlineChanged
    in
    div []
        [ div [ class "mb-6" ]
            [ div [ class "mb-10" ]
                [ p [ class "input-label mb-6" ] [ text_ "community.actions.form.validity_label" ]
                , div [ class "flex" ]
                    [ div [ class "form-switch inline-block align-middle" ]
                        [ input
                            [ type_ "checkbox"
                            , id "expiration-toggle"
                            , name "expiration-toggle"
                            , class "form-switch-checkbox"
                            , checked (model.form.validation /= NoValidation)
                            , onCheck ToggleValidity
                            ]
                            []
                        , label [ class "form-switch-label", for "expiration-toggle" ] []
                        ]
                    , label [ class "flex text-body text-green", for "expiration-toggle" ]
                        [ p [ class "font-bold mr-1" ]
                            [ if model.form.validation == NoValidation then
                                text_ "community.actions.form.validation_off"

                              else
                                text_ "community.actions.form.validation_on"
                            ]
                        , text_ "community.actions.form.validation_detail"
                        ]
                    ]
                ]
            ]
        , div
            [ class "" ]
            [ div [ class "mb-3 flex flex-row text-body items-bottom" ]
                [ input
                    [ id "date"
                    , type_ "checkbox"
                    , class "form-checkbox mr-2 p-1"
                    , checked (hasDateValidation model.form.validation)
                    , onCheck ToggleDeadline
                    ]
                    []
                , label
                    [ for "date", class "flex" ]
                    [ p [ class "font-bold mr-1" ] [ text_ "community.actions.form.date_validity" ]
                    , text_ "community.actions.form.date_validity_details"
                    ]
                ]
            , case model.form.validation of
                NoValidation ->
                    text ""

                Validations dateValidation _ ->
                    case dateValidation of
                        Just validation ->
                            div []
                                [ span [ class "input-label" ]
                                    [ text_ "community.actions.form.date_label" ]
                                , div [ class "mb-10" ]
                                    [ MaskedDate.input
                                        { dateOptions
                                            | pattern = "##/##/####"
                                            , inputCharacter = '#'
                                        }
                                        [ class "input"
                                        , classList [ ( "border-red", hasErrors validation ) ]
                                        , placeholder "mm/dd/yyyy"
                                        ]
                                        model.form.deadlineState
                                        (getInput validation)
                                    , viewFieldErrors (listErrors shared.translations validation)
                                    ]
                                ]

                        Nothing ->
                            text ""
            , div [ class "mb-6 flex flex-row text-body items-bottom" ]
                [ input
                    [ id "quantity"
                    , type_ "checkbox"
                    , class "form-checkbox mr-2"
                    , checked (hasUnitValidation model.form.validation)
                    , onCheck ToggleUsages
                    ]
                    []
                , label [ for "quantity", class "flex" ]
                    [ p [ class "font-bold mr-1" ] [ text_ "community.actions.form.quantity_validity" ]
                    , text_ "community.actions.form.quantity_validity_details"
                    ]
                ]
            ]
        , case model.form.validation of
            NoValidation ->
                text ""

            Validations _ usagesValidation ->
                case usagesValidation of
                    Just validation ->
                        div []
                            [ span [ class "input-label" ]
                                [ text_ "community.actions.form.quantity_label" ]
                            , div [ class "mb-10" ]
                                [ input
                                    [ type_ "number"
                                    , class "input"
                                    , classList [ ( "border-red", hasErrors validation ) ]
                                    , value (getInput validation |> String.fromInt)
                                    , onInput EnteredUsages
                                    ]
                                    []
                                , viewFieldErrors (listErrors shared.translations validation)
                                ]
                            ]

                    Nothing ->
                        text ""
        ]


viewVerifications : LoggedIn.Model -> Model -> Community -> Html Msg
viewVerifications ({ shared } as loggedIn) model community =
    let
        text_ s =
            text (t shared.translations s)
    in
    div [ class "mb-10" ]
        [ div [ class "flex flex-row justify-between mb-6" ]
            [ p [ class "input-label" ]
                [ text_ "community.actions.form.verification_label" ]
            ]
        , div [ class "mb-6" ]
            [ label [ class "inline-flex items-center" ]
                [ input
                    [ type_ "radio"
                    , class "form-radio h-5 w-5 text-green"
                    , name "verification"
                    , value "automatic"
                    , checked (model.form.verification == Automatic)
                    , onClick (SetVerification "automatic")
                    ]
                    []
                , span
                    [ class "flex ml-3 text-body"
                    , classList [ ( "text-green", model.form.verification == Automatic ) ]
                    ]
                    [ p [ class "font-bold mr-1" ] [ text_ "community.actions.form.automatic" ]
                    , text_ "community.actions.form.automatic_detail"
                    ]
                ]
            ]
        , div [ class "mb-6" ]
            [ label [ class "inline-flex items-center" ]
                [ input
                    [ type_ "radio"
                    , class "form-radio h-5 w-5 text-green"
                    , name "verification"
                    , value "manual"
                    , checked (model.form.verification /= Automatic)
                    , onClick (SetVerification "manual")
                    ]
                    []
                , span
                    [ class "flex ml-3 text-body"
                    , classList [ ( "text-green", model.form.verification /= Automatic ) ]
                    ]
                    [ p [ class "font-bold mr-1" ] [ text_ "community.actions.form.manual" ]
                    , text_ "community.actions.form.manual_detail"
                    ]
                ]
            ]
        , if model.form.verification /= Automatic then
            viewManualVerificationForm loggedIn model community

          else
            text ""
        ]


viewManualVerificationForm : LoggedIn.Model -> Model -> Community -> Html Msg
viewManualVerificationForm ({ shared } as loggedIn) model community =
    let
        text_ s =
            text (t shared.translations s)
    in
    case model.form.verification of
        Automatic ->
            text ""

        Manual selectedVerifiers verificationReward minVotes ->
            div [ class "w-2/5" ]
                [ span [ class "input-label" ]
                    [ text_ "community.actions.form.verifiers_label" ]
                , div []
                    [ viewVerifierSelect shared model False
                    , viewSelectedVerifiers shared selectedVerifiers
                    ]
                , span [ class "input-label" ]
                    [ text_ "community.actions.form.verifiers_reward_label" ]
                , div [ class "mb-10" ]
                    [ div [ class "flex flex-row border rounded-sm" ]
                        [ input
                            [ class "input w-4/5 border-none"
                            , type_ "number"
                            , placeholder "0.00"
                            , onInput EnteredVerifierReward
                            , value (getInput verificationReward |> String.fromFloat)
                            ]
                            []
                        , span
                            [ class "w-1/5 flex input-token rounded-r-sm" ]
                            [ text (Eos.symbolToString community.symbol) ]
                        ]
                    , viewFieldErrors (listErrors shared.translations verificationReward)
                    ]
                , div [ class "flex flex-row justify-between" ]
                    [ p [ class "input-label" ]
                        [ text_ "community.actions.form.votes_label" ]
                    ]
                , div []
                    [ input
                        [ class "w-full input border rounded-sm"
                        , type_ "number"
                        , onInput EnteredMinVotes
                        , value (getInput minVotes |> String.fromInt)
                        ]
                        []
                    , viewFieldErrors (listErrors shared.translations minVotes)
                    ]
                ]


viewSelectedVerifiers : Shared -> List Profile -> Html Msg
viewSelectedVerifiers shared selectedVerifiers =
    let
        ipfsUrl =
            shared.endpoints.ipfs

        text_ s =
            text (t shared.translations s)
    in
    div [ class "flex flex-row mt-3 mb-10 flex-wrap" ]
        (selectedVerifiers
            |> List.map
                (\p ->
                    div
                        [ class "flex flex-col m-3 items-center" ]
                        [ div [ class "relative h-10 w-12 ml-2" ]
                            [ Avatar.view ipfsUrl p.avatar "h-10 w-10"
                            , div
                                [ onClick (OnRemoveVerifier p)
                                , class "absolute top-0 right-0 z-10 rounded-full h-6 w-6 flex items-center"
                                ]
                                [ Icons.remove "" ]
                            ]
                        , span [ class "mt-2 text-black font-sans text-body leading-normal" ]
                            [ text (Eos.nameToString p.accountName) ]
                        ]
                )
        )


viewFieldErrors : List String -> Html msg
viewFieldErrors errors =
    div [ class "form-field-error" ]
        (List.map
            (\e ->
                span [ class "field-error" ] [ text e ]
            )
            errors
        )



-- Configure Select


filter : Int -> (a -> String) -> String -> List a -> Maybe (List a)
filter minChars toLabel query items =
    if String.length query < minChars then
        Nothing

    else
        items
            |> Simple.Fuzzy.filter toLabel query
            |> Just


selectConfig : Shared -> Bool -> Select.Config Msg Profile
selectConfig shared isDisabled =
    Select.newConfig
        { onSelect = OnSelectVerifier
        , toLabel = \p -> Eos.nameToString p.accountName
        , filter = filter 2 (\p -> Eos.nameToString p.accountName)
        }
        |> Select.withMultiSelection True
        |> Select.withInputClass "form-input h-12 w-full font-sans placeholder-gray-900"
        |> Select.withClear False
        |> Select.withMultiInputItemContainerClass "hidden h-0"
        |> Select.withNotFound "No matches"
        |> Select.withNotFoundClass "text-red  border-solid border-gray-100 border rounded z-30 bg-white w-select"
        |> Select.withNotFoundStyles [ ( "padding", "0 2rem" ) ]
        |> Select.withDisabled isDisabled
        |> Select.withHighlightedItemClass "autocomplete-item-highlight"
        |> Select.withPrompt (t shared.translations "community.actions.form.verifier_placeholder")
        |> Select.withItemHtml (viewAutoCompleteItem shared)
        |> Select.withMenuClass "border-t-none border-solid border-gray-100 border rounded-b z-30 bg-white"


viewAutoCompleteItem : Shared -> Profile -> Html Never
viewAutoCompleteItem shared profile =
    let
        ipfsUrl =
            shared.endpoints.ipfs
    in
    div [ class "pt-3 pl-3 flex flex-row items-center w-select z-30" ]
        [ div [ class "pr-3" ] [ Avatar.view ipfsUrl profile.avatar "h-7 w-7" ]
        , div [ class "flex flex-col font-sans border-b border-gray-500 pb-3 w-full" ]
            [ span [ class "text-black text-body leading-loose" ]
                [ text (Eos.nameToString profile.accountName) ]
            , span [ class "leading-caption uppercase text-green text-caption" ]
                [ case profile.userName of
                    Just name ->
                        text name

                    Nothing ->
                        text ""
                ]
            ]
        ]


viewVerifierSelect : Shared -> Model -> Bool -> Html Msg
viewVerifierSelect shared model isDisabled =
    let
        users =
            case model.status of
                Loaded community ->
                    community.members

                _ ->
                    []
    in
    case model.form.verification of
        Automatic ->
            text ""

        Manual selectedUsers _ _ ->
            div []
                [ Html.map SelectMsg
                    (Select.view (selectConfig shared isDisabled)
                        model.multiSelectState
                        users
                        selectedUsers
                    )
                ]



-- UTILS


jsAddressToMsg : List String -> Value -> Maybe Msg
jsAddressToMsg addr val =
    case addr of
        "ValidateDeadline" :: _ ->
            Json.decodeValue
                (Json.oneOf
                    [ Json.field "date" Json.string
                        |> Json.map Ok
                    , Json.succeed (Err val)
                    ]
                )
                val
                |> Result.map (Just << SaveAction)
                |> Result.withDefault (Just GotInvalidDate)

        "UploadAction" :: _ ->
            Json.decodeValue
                (Json.oneOf
                    [ Json.field "transactionId" Json.string
                        |> Json.map Ok
                    , Json.succeed (Err val)
                    ]
                )
                val
                |> Result.map (Just << GotSaveAction)
                |> Result.withDefault Nothing

        _ ->
            Nothing


msgToString : Msg -> List String
msgToString msg =
    case msg of
        CompletedCommunityLoad _ ->
            [ "CompletedCommunityLoad" ]

        OnSelectVerifier _ ->
            [ "OnSelectVerifier" ]

        OnRemoveVerifier _ ->
            [ "OnRemoveVerifier" ]

        EnteredDescription _ ->
            [ "EnteredDescription" ]

        EnteredReward _ ->
            [ "EnteredReward" ]

        EnteredDeadline _ ->
            [ "EnteredDeadline" ]

        EnteredMinVotes _ ->
            [ "EnteredMinVotes" ]

        EnteredUsages _ ->
            [ "EnteredUsages" ]

        DeadlineChanged _ ->
            [ "DeadlineChanged" ]

        SelectMsg _ ->
            [ "SelectMsg" ]

        ToggleValidity _ ->
            [ "ToggleValidity" ]

        ToggleDeadline _ ->
            [ "ToggleDeadline" ]

        ToggleUsages _ ->
            [ "ToggleDeadline" ]

        EnteredVerifierReward _ ->
            [ "EnteredVerifierReward" ]

        SetVerification _ ->
            [ "SetVerification" ]

        ValidateForm ->
            [ "ValidateDeadline" ]

        ValidateDeadline ->
            [ "ValidateDeadline" ]

        SaveAction _ ->
            [ "SaveAction" ]

        GotInvalidDate ->
            [ "GotInvalidDate" ]

        GotSaveAction _ ->
            [ "GotSaveAction" ]
