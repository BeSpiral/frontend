module Page.Community.Objectives exposing (Model, Msg, init, jsAddressToMsg, msgToString, receiveBroadcast, update, view)

import Action exposing (Action, Msg(..))
import AssocList exposing (Dict)
import Browser.Dom
import Cambiatus.Enum.Permission as Permission
import Community
import Dict
import Eos
import Eos.Account
import Form
import Form.File
import Form.Text
import Html exposing (Html, a, b, br, button, details, div, h1, h2, h3, h4, img, li, p, span, summary, text, ul)
import Html.Attributes exposing (alt, class, classList, disabled, id, src, style, tabindex, title)
import Html.Attributes.Aria exposing (ariaHasPopup, ariaHidden, ariaLabel, role)
import Html.Events exposing (onClick)
import Icons
import Json.Decode as Decode
import Json.Encode as Encode
import List.Extra
import Log
import Markdown
import Maybe.Extra
import Page
import RemoteData
import Route
import Session.LoggedIn as LoggedIn
import Session.Shared exposing (Shared)
import Sha256
import Task
import Time
import Time.Extra
import Translation
import UpdateResult as UR
import Url
import Utils
import View.Components exposing (intersectionObserver)
import View.Feedback
import View.Modal



-- MODEL


type alias Model =
    { shownObjectives :
        Dict
            Action.ObjectiveId
            { visibleAction : Maybe Int
            , visibleActionHeight : Maybe Float
            , previousVisibleAction : Maybe Int
            , previousVisibleActionHeight : Maybe Float
            , openHeight : Maybe Float
            , closedHeight : Maybe Float
            , isClosing : Bool
            }
    , highlightedAction : Maybe { objectiveId : Action.ObjectiveId, actionId : Maybe Int }
    , sharingAction : Maybe Action
    , claimingStatus : ClaimingStatus
    }


type ClaimingStatus
    = NotClaiming
    | Claiming { position : Int, action : Action, proof : Proof }


type Proof
    = NoProofNecessary
    | WithProof (Form.Model Form.File.SingleModel) ProofCode


type ProofCode
    = NoCodeNecessary
    | GeneratingCode
    | WithCode
        { code : String
        , expiration : Time.Posix
        , generation : Time.Posix
        }


init : Route.SelectedObjective -> LoggedIn.Model -> UpdateResult
init selectedObjective _ =
    UR.init
        { highlightedAction =
            case selectedObjective of
                Route.WithNoObjectiveSelected ->
                    Nothing

                Route.WithObjectiveSelected { id, action } ->
                    Just { objectiveId = Action.objectiveIdFromInt id, actionId = action }
        , shownObjectives =
            case selectedObjective of
                Route.WithNoObjectiveSelected ->
                    AssocList.empty

                Route.WithObjectiveSelected { id } ->
                    AssocList.fromList
                        [ ( Action.objectiveIdFromInt id
                          , { visibleAction = Nothing
                            , visibleActionHeight = Nothing
                            , previousVisibleAction = Nothing
                            , previousVisibleActionHeight = Nothing
                            , openHeight = Nothing
                            , closedHeight = Nothing
                            , isClosing = False
                            }
                          )
                        ]
        , sharingAction = Nothing
        , claimingStatus = NotClaiming
        }
        |> UR.addExt (LoggedIn.RequestedReloadCommunityField Community.ObjectivesField)
        |> UR.addCmd (Browser.Dom.setViewport 0 0 |> Task.attempt (\_ -> NoOp))



-- TYPES


type Msg
    = NoOp
    | CompletedLoadObjectives (List Community.Objective)
    | ClickedToggleObjectiveVisibility Community.Objective
    | FinishedOpeningActions Community.Objective
    | FinishedClosingObjective Community.Objective
    | GotObjectiveDetailsHeight Community.Objective (Result Browser.Dom.Error Browser.Dom.Element)
    | GotObjectiveSummaryHeight Community.Objective (Result Browser.Dom.Error Browser.Dom.Element)
    | GotVisibleActionViewport { objectiveId : Action.ObjectiveId, actionId : Int } (Result Browser.Dom.Error Browser.Dom.Viewport)
    | ClickedScrollToAction Action
    | ClickedShareAction Action
    | ClickedClaimAction { position : Int, action : Action }
    | ClickedCloseClaimModal
    | StartedIntersecting String
    | StoppedIntersecting String
    | ConfirmedClaimAction
    | ConfirmedClaimActionWithPhotoProof String
    | GotPhotoProofFormMsg (Form.Msg Form.File.SingleModel)
    | GotUint64Name String
    | CompletedClaimingAction (Result Encode.Value ())
    | CopiedShareLinkToClipboard Int


type alias UpdateResult =
    UR.UpdateResult Model Msg (LoggedIn.External Msg)



-- UPDATE


update : Msg -> Model -> LoggedIn.Model -> UpdateResult
update msg model loggedIn =
    case msg of
        NoOp ->
            UR.init model

        CompletedLoadObjectives objectives ->
            let
                scrollActionIntoView =
                    case model.highlightedAction of
                        Nothing ->
                            identity

                        Just { objectiveId, actionId } ->
                            let
                                maybeAction =
                                    List.Extra.find (\objective -> objective.id == objectiveId) objectives
                                        |> Maybe.andThen
                                            (\foundObjective ->
                                                List.Extra.find (\action -> Just action.id == actionId) foundObjective.actions
                                            )

                                getHighlightedObjectiveSummaryHeight =
                                    case List.Extra.find (\objective -> objective.id == objectiveId) objectives of
                                        Just objective ->
                                            UR.addCmd
                                                (Browser.Dom.getElement (objectiveSummaryId objective)
                                                    |> Task.attempt (GotObjectiveSummaryHeight objective)
                                                )

                                        Nothing ->
                                            identity
                            in
                            case maybeAction of
                                Nothing ->
                                    let
                                        hasObjective =
                                            List.any (\objective -> objective.id == objectiveId) objectives
                                    in
                                    if hasObjective then
                                        UR.addPort
                                            { responseAddress = NoOp
                                            , responseData = Encode.null
                                            , data =
                                                Encode.object
                                                    [ ( "name", Encode.string "scrollIntoView" )
                                                    , ( "id", Encode.string (objectiveDetailsId { id = objectiveId }) )
                                                    ]
                                            }
                                            >> getHighlightedObjectiveSummaryHeight

                                    else
                                        identity

                                Just highlightedAction ->
                                    UR.addPort
                                        { responseAddress = NoOp
                                        , responseData = Encode.null
                                        , data =
                                            Encode.object
                                                [ ( "name", Encode.string "scrollIntoView" )
                                                , ( "id", Encode.string (actionCardId highlightedAction) )
                                                ]
                                        }
                                        >> getHighlightedObjectiveSummaryHeight

                claimingStatus =
                    case model.highlightedAction of
                        Nothing ->
                            NotClaiming

                        Just { objectiveId, actionId } ->
                            objectives
                                |> List.Extra.find (\objective -> objective.id == objectiveId)
                                |> Maybe.andThen
                                    (\objective ->
                                        let
                                            maybePosition =
                                                List.Extra.findIndex (\action -> Just action.id == actionId) objective.actions

                                            maybeAction =
                                                List.Extra.find (\action -> Just action.id == actionId) objective.actions
                                        in
                                        Maybe.map2
                                            (\position action ->
                                                Claiming
                                                    { position = position + 1
                                                    , action = action
                                                    , proof =
                                                        if action.hasProofPhoto then
                                                            WithProof
                                                                ({ fileUrl = Nothing
                                                                 , aspectRatio = Nothing
                                                                 }
                                                                    |> Form.File.initSingle
                                                                    |> Form.init
                                                                )
                                                                (if action.hasProofCode then
                                                                    GeneratingCode

                                                                 else
                                                                    NoCodeNecessary
                                                                )

                                                        else
                                                            NoProofNecessary
                                                    }
                                            )
                                            maybePosition
                                            maybeAction
                                    )
                                |> Maybe.withDefault NotClaiming

                generateProofCodePort =
                    case claimingStatus of
                        Claiming { proof } ->
                            case proof of
                                WithProof _ _ ->
                                    UR.addPort
                                        { responseAddress = msg
                                        , responseData = Encode.null
                                        , data =
                                            Encode.object
                                                [ ( "name", Encode.string "accountNameToUint64" )
                                                , ( "accountName", Eos.Account.encodeName loggedIn.accountName )
                                                ]
                                        }

                                NoProofNecessary ->
                                    identity

                        _ ->
                            identity
            in
            { model | claimingStatus = claimingStatus }
                |> UR.init
                |> scrollActionIntoView
                |> generateProofCodePort

        ClickedToggleObjectiveVisibility objective ->
            { model
                | shownObjectives =
                    AssocList.update objective.id
                        (\currentValue ->
                            case currentValue of
                                Nothing ->
                                    Just
                                        { visibleAction = Nothing
                                        , visibleActionHeight = Nothing
                                        , previousVisibleAction = Nothing
                                        , previousVisibleActionHeight = Nothing
                                        , openHeight = Nothing
                                        , closedHeight = Nothing
                                        , isClosing = False
                                        }

                                Just value ->
                                    Just { value | isClosing = True }
                        )
                        model.shownObjectives
                , highlightedAction = Nothing
            }
                |> UR.init
                |> UR.addCmd
                    (Browser.Dom.getElement (objectiveSummaryId objective)
                        |> Task.attempt (GotObjectiveSummaryHeight objective)
                    )

        FinishedOpeningActions objective ->
            model
                |> UR.init
                |> UR.addCmd
                    (Browser.Dom.getElement (objectiveDetailsId objective)
                        |> Task.attempt (GotObjectiveDetailsHeight objective)
                    )

        FinishedClosingObjective objective ->
            { model | shownObjectives = AssocList.remove objective.id model.shownObjectives }
                |> UR.init

        GotObjectiveDetailsHeight objective (Ok { element }) ->
            { model
                | shownObjectives =
                    AssocList.update objective.id
                        (Maybe.map (\value -> { value | openHeight = Just element.height }))
                        model.shownObjectives
            }
                |> UR.init

        GotObjectiveDetailsHeight _ (Err (Browser.Dom.NotFound id)) ->
            model
                |> UR.init
                |> UR.logImpossible msg
                    "Couldn't get objective details height"
                    (Just loggedIn.accountName)
                    { moduleName = "Page.Community.Objectives", function = "update" }
                    [ { name = "Error"
                      , extras =
                            Dict.fromList
                                [ ( "type", Encode.string "Browser.Dom.NotFound" )
                                , ( "id", Encode.string id )
                                ]
                      }
                    ]

        GotObjectiveSummaryHeight objective (Ok { element }) ->
            { model
                | shownObjectives =
                    AssocList.update objective.id
                        (Maybe.map (\value -> { value | closedHeight = Just element.height }))
                        model.shownObjectives
            }
                |> UR.init

        GotObjectiveSummaryHeight _ (Err (Browser.Dom.NotFound id)) ->
            model
                |> UR.init
                |> UR.logImpossible msg
                    "Couldn't get objective summary height"
                    (Just loggedIn.accountName)
                    { moduleName = "Page.Community.Objectives", function = "update" }
                    [ { name = "Error"
                      , extras =
                            Dict.fromList
                                [ ( "type", Encode.string "Browser.Dom.NotFound" )
                                , ( "id", Encode.string id )
                                ]
                      }
                    ]

        GotVisibleActionViewport { objectiveId, actionId } (Ok { viewport }) ->
            { model
                | shownObjectives =
                    model.shownObjectives
                        |> AssocList.update objectiveId
                            (\maybeValue ->
                                case maybeValue of
                                    Nothing ->
                                        Just
                                            { visibleAction = Just actionId
                                            , visibleActionHeight = Just viewport.height
                                            , previousVisibleAction = Nothing
                                            , previousVisibleActionHeight = Nothing
                                            , openHeight = Nothing
                                            , closedHeight = Nothing
                                            , isClosing = False
                                            }

                                    Just value ->
                                        Just { value | visibleActionHeight = Just viewport.height }
                            )
            }
                |> UR.init

        GotVisibleActionViewport _ (Err _) ->
            model
                |> UR.init

        ClickedScrollToAction action ->
            model
                |> UR.init
                |> UR.addPort
                    { responseAddress = NoOp
                    , responseData = Encode.null
                    , data =
                        Encode.object
                            [ ( "name", Encode.string "smoothHorizontalScroll" )
                            , ( "containerId", Encode.string (objectiveContainerId action.objective) )
                            , ( "targetId", Encode.string (actionCardId action) )
                            ]
                    }

        ClickedShareAction action ->
            let
                sharePort =
                    if loggedIn.shared.canShare then
                        { responseAddress = msg
                        , responseData = Encode.null
                        , data =
                            Encode.object
                                [ ( "name", Encode.string "share" )
                                , ( "title", Markdown.encode action.description )
                                , ( "url"
                                  , Route.CommunityObjectives
                                        (Route.WithObjectiveSelected
                                            { id = Action.objectiveIdToInt action.objective.id
                                            , action = Just action.id
                                            }
                                        )
                                        |> Route.addRouteToUrl loggedIn.shared
                                        |> Url.toString
                                        |> Encode.string
                                  )
                                ]
                        }

                    else
                        { responseAddress = msg
                        , responseData = Encode.int action.id
                        , data =
                            Encode.object
                                [ ( "name", Encode.string "copyToClipboard" )
                                , ( "id", Encode.string "share-fallback-input" )
                                ]
                        }
            in
            { model | sharingAction = Just action }
                |> UR.init
                |> UR.addPort sharePort

        ClickedClaimAction { position, action } ->
            let
                proof =
                    if action.hasProofPhoto then
                        WithProof
                            ({ fileUrl = Nothing
                             , aspectRatio = Nothing
                             }
                                |> Form.File.initSingle
                                |> Form.init
                            )
                            (if action.hasProofCode then
                                GeneratingCode

                             else
                                NoCodeNecessary
                            )

                    else
                        NoProofNecessary

                generateProofCodePort =
                    UR.addPort
                        { responseAddress = msg
                        , responseData = Encode.null
                        , data =
                            Encode.object
                                [ ( "name", Encode.string "accountNameToUint64" )
                                , ( "accountName", Eos.Account.encodeName loggedIn.accountName )
                                ]
                        }
            in
            { model
                | claimingStatus =
                    Claiming
                        { position = position
                        , action = action
                        , proof = proof
                        }
            }
                |> UR.init
                |> UR.addExt (LoggedIn.SetUpdateTimeEvery 1000)
                |> generateProofCodePort

        ClickedCloseClaimModal ->
            { model | claimingStatus = NotClaiming }
                |> UR.init
                |> UR.addExt (LoggedIn.SetUpdateTimeEvery (60 * 1000))

        StartedIntersecting actionCard ->
            case Community.getField loggedIn.selectedCommunity .objectives of
                RemoteData.Success ( _, objectives ) ->
                    let
                        maybeActionIdAndParentObjective =
                            idFromActionCardId actionCard
                                |> Maybe.andThen
                                    (\actionId ->
                                        objectives
                                            |> List.Extra.find
                                                (\objective ->
                                                    objective.actions
                                                        |> List.map .id
                                                        |> List.member actionId
                                                )
                                            |> Maybe.map (Tuple.pair actionId)
                                    )
                    in
                    case maybeActionIdAndParentObjective of
                        Nothing ->
                            model
                                |> UR.init

                        Just ( actionId, parentObjective ) ->
                            { model
                                | shownObjectives =
                                    AssocList.update parentObjective.id
                                        (\maybeValue ->
                                            case maybeValue of
                                                Nothing ->
                                                    Just
                                                        { visibleAction = Just actionId
                                                        , visibleActionHeight = Nothing
                                                        , previousVisibleAction = Nothing
                                                        , previousVisibleActionHeight = Nothing
                                                        , openHeight = Nothing
                                                        , closedHeight = Nothing
                                                        , isClosing = False
                                                        }

                                                Just value ->
                                                    Just
                                                        { visibleAction = Just actionId
                                                        , visibleActionHeight = Nothing
                                                        , previousVisibleAction = value.visibleAction
                                                        , previousVisibleActionHeight = value.visibleActionHeight
                                                        , openHeight = value.openHeight
                                                        , closedHeight = value.closedHeight
                                                        , isClosing = value.isClosing
                                                        }
                                        )
                                        model.shownObjectives
                            }
                                |> UR.init
                                |> UR.addCmd
                                    (Browser.Dom.getViewportOf actionCard
                                        |> Task.attempt
                                            (GotVisibleActionViewport { objectiveId = parentObjective.id, actionId = actionId })
                                    )

                _ ->
                    model
                        |> UR.init
                        |> UR.logImpossible msg
                            "Action started showing up, but objectives weren't loaded"
                            (Just loggedIn.accountName)
                            { moduleName = "Page.Community.Objectives", function = "update" }
                            [ Log.contextFromCommunity loggedIn.selectedCommunity ]

        StoppedIntersecting targetId ->
            let
                newShownObjectives =
                    AssocList.foldl
                        (\objectiveId value currDict ->
                            if value.visibleAction == idFromActionCardId targetId then
                                AssocList.insert objectiveId
                                    { visibleAction = value.previousVisibleAction
                                    , visibleActionHeight = value.previousVisibleActionHeight
                                    , previousVisibleAction = Nothing
                                    , previousVisibleActionHeight = Nothing
                                    , openHeight = value.openHeight
                                    , closedHeight = value.closedHeight
                                    , isClosing = value.isClosing
                                    }
                                    currDict

                            else if value.previousVisibleAction == idFromActionCardId targetId then
                                AssocList.insert objectiveId
                                    { value
                                        | previousVisibleAction = Nothing
                                        , previousVisibleActionHeight = Nothing
                                    }
                                    currDict

                            else
                                AssocList.insert objectiveId value currDict
                        )
                        AssocList.empty
                        model.shownObjectives
            in
            { model | shownObjectives = newShownObjectives }
                |> UR.init

        ConfirmedClaimAction ->
            case model.claimingStatus of
                Claiming { action } ->
                    UR.init model
                        |> UR.addPort
                            { responseAddress = msg
                            , responseData = Encode.null
                            , data =
                                Eos.encodeTransaction
                                    [ { accountName = loggedIn.shared.contracts.community
                                      , name = "claimaction"
                                      , authorization =
                                            { actor = loggedIn.accountName
                                            , permissionName = Eos.Account.samplePermission
                                            }
                                      , data =
                                            Action.encodeClaimAction
                                                { communityId = action.objective.community.symbol
                                                , actionId = action.id
                                                , claimer = loggedIn.accountName
                                                , proof = Nothing
                                                }
                                      }
                                    ]
                            }
                        |> LoggedIn.withPrivateKey loggedIn
                            [ Permission.Claim ]
                            model
                            { successMsg = msg, errorMsg = ClickedCloseClaimModal }

                _ ->
                    UR.init model
                        |> UR.logImpossible msg
                            "Confirmed claim action, but wasn't claiming"
                            (Just loggedIn.accountName)
                            { moduleName = "Page.Community.Objectives", function = "update" }
                            []

        ConfirmedClaimActionWithPhotoProof proofUrl ->
            case model.claimingStatus of
                Claiming { action, proof } ->
                    case proof of
                        WithProof _ proofCode ->
                            let
                                claimPort maybeProofCode =
                                    { responseAddress = msg
                                    , responseData = Encode.null
                                    , data =
                                        Eos.encodeTransaction
                                            [ { accountName = loggedIn.shared.contracts.community
                                              , name = "claimaction"
                                              , authorization =
                                                    { actor = loggedIn.accountName
                                                    , permissionName = Eos.Account.samplePermission
                                                    }
                                              , data =
                                                    Action.encodeClaimAction
                                                        { communityId = action.objective.community.symbol
                                                        , actionId = action.id
                                                        , claimer = loggedIn.accountName
                                                        , proof =
                                                            Just
                                                                { photo = proofUrl
                                                                , proofCode = maybeProofCode
                                                                }
                                                        }
                                              }
                                            ]
                                    }
                            in
                            case proofCode of
                                GeneratingCode ->
                                    UR.init model

                                NoCodeNecessary ->
                                    UR.init model
                                        |> UR.addPort (claimPort Nothing)
                                        |> LoggedIn.withPrivateKey loggedIn
                                            [ Permission.Claim ]
                                            model
                                            { successMsg = msg, errorMsg = NoOp }

                                WithCode { code, generation } ->
                                    UR.init model
                                        |> UR.addPort
                                            (claimPort
                                                (Just
                                                    { code = code
                                                    , time = generation
                                                    }
                                                )
                                            )
                                        |> LoggedIn.withPrivateKey loggedIn
                                            [ Permission.Claim ]
                                            model
                                            { successMsg = msg, errorMsg = NoOp }

                        _ ->
                            UR.init model

                _ ->
                    UR.init model
                        |> UR.logImpossible msg
                            "Confirmed claim action with proof, but wasn't claiming"
                            (Just loggedIn.accountName)
                            { moduleName = "Page.Community.Objectives", function = "update" }
                            []

        GotPhotoProofFormMsg subMsg ->
            case model.claimingStatus of
                Claiming { position, action, proof } ->
                    case proof of
                        WithProof formModel proofCode ->
                            Form.update loggedIn.shared subMsg formModel
                                |> UR.fromChild
                                    (\newFormModel ->
                                        { model
                                            | claimingStatus =
                                                Claiming
                                                    { position = position
                                                    , action = action
                                                    , proof = WithProof newFormModel proofCode
                                                    }
                                        }
                                    )
                                    GotPhotoProofFormMsg
                                    LoggedIn.addFeedback
                                    model

                        NoProofNecessary ->
                            UR.init model

                NotClaiming ->
                    UR.init model

        GotUint64Name uint64Name ->
            case model.claimingStatus of
                Claiming { position, action, proof } ->
                    case proof of
                        WithProof formModel _ ->
                            let
                                proofCode =
                                    generateProofCode action
                                        uint64Name
                                        loggedIn.shared.now

                                expiration =
                                    Time.Extra.add Time.Extra.Minute
                                        30
                                        loggedIn.shared.timezone
                                        loggedIn.shared.now
                            in
                            { model
                                | claimingStatus =
                                    Claiming
                                        { position = position
                                        , action = action
                                        , proof =
                                            WithProof formModel
                                                (if action.hasProofCode then
                                                    WithCode
                                                        { code = proofCode
                                                        , expiration = expiration
                                                        , generation = loggedIn.shared.now
                                                        }

                                                 else
                                                    NoCodeNecessary
                                                )
                                        }
                            }
                                |> UR.init

                        NoProofNecessary ->
                            UR.init model

                _ ->
                    UR.init model

        CompletedClaimingAction (Ok ()) ->
            case loggedIn.selectedCommunity of
                RemoteData.Success community ->
                    { model | claimingStatus = NotClaiming }
                        |> UR.init
                        |> UR.addExt (LoggedIn.ShowFeedback View.Feedback.Success (loggedIn.shared.translators.tr "dashboard.check_claim.success" [ ( "symbolCode", Eos.symbolToSymbolCodeString community.symbol ) ]))
                        |> UR.addExt (LoggedIn.SetUpdateTimeEvery (60 * 1000))
                        |> UR.addCmd
                            (Eos.Account.nameToString loggedIn.accountName
                                |> Route.ProfileClaims
                                |> Route.pushUrl loggedIn.shared.navKey
                            )

                _ ->
                    { model | claimingStatus = NotClaiming }
                        |> UR.init
                        |> UR.addExt (LoggedIn.SetUpdateTimeEvery (60 * 1000))
                        |> UR.logImpossible msg
                            "Completed claiming action, but community wasn't loaded"
                            (Just loggedIn.accountName)
                            { moduleName = "Page.Community.Objectives", function = "update" }
                            []
                        |> UR.addCmd
                            (Eos.Account.nameToString loggedIn.accountName
                                |> Route.ProfileClaims
                                |> Route.pushUrl loggedIn.shared.navKey
                            )

        CompletedClaimingAction (Err val) ->
            { model | claimingStatus = NotClaiming }
                |> UR.init
                |> UR.addExt (LoggedIn.ShowFeedback View.Feedback.Failure (loggedIn.shared.translators.t "dashboard.check_claim.failure"))
                |> UR.addExt (LoggedIn.SetUpdateTimeEvery (60 * 1000))
                |> UR.logJsonValue msg
                    (Just loggedIn.accountName)
                    "Got an error when claiming an action"
                    { moduleName = "Page.Community.Objectives", function = "update" }
                    []
                    val

        CopiedShareLinkToClipboard actionId ->
            model
                |> UR.init
                |> UR.addExt
                    (LoggedIn.ShowFeedback View.Feedback.Success
                        (loggedIn.shared.translators.t "copied_to_clipboard")
                    )
                |> UR.addCmd
                    (Browser.Dom.focus (shareActionButtonId actionId)
                        |> Task.attempt (\_ -> NoOp)
                    )



-- VIEW


view : LoggedIn.Model -> Model -> { title : String, content : Html Msg }
view loggedIn model =
    let
        title =
            loggedIn.shared.translators.t "community.objectives.title"
    in
    { title = title
    , content =
        case loggedIn.selectedCommunity of
            RemoteData.Success community ->
                if community.hasObjectives then
                    viewPage loggedIn community model

                else
                    Page.fullPageNotFound title (loggedIn.shared.translators.t "community.objectives.disabled_objectives_description")

            RemoteData.Loading ->
                Page.fullPageLoading loggedIn.shared

            RemoteData.NotAsked ->
                Page.fullPageLoading loggedIn.shared

            RemoteData.Failure err ->
                Page.fullPageGraphQLError title err
    }


viewPage : LoggedIn.Model -> Community.Model -> Model -> Html Msg
viewPage loggedIn community model =
    let
        { t, tr } =
            loggedIn.shared.translators
    in
    div [ class "container mx-auto px-4 pt-8 mb-20" ]
        [ h1
            [ class "lg:w-2/3 lg:mx-auto"
            , ariaLabel (t "community.objectives.earn" ++ " " ++ Eos.symbolToSymbolCodeString community.symbol)
            ]
            [ span [ ariaHidden True ] [ text <| t "community.objectives.earn" ]
            , text " "
            , span [ class "font-bold", ariaHidden True ]
                [ text (Eos.symbolToSymbolCodeString community.symbol) ]
            ]
        , div [ class "mt-4 bg-white rounded relative lg:w-2/3 lg:mx-auto" ]
            [ p
                [ class "p-4"
                ]
                [ span [ class "sr-only" ] [ text <| t "community.objectives.complete_actions" ++ " " ++ Eos.symbolToSymbolCodeString community.symbol ]
                , span [ ariaHidden True ] [ text <| t "community.objectives.complete_actions" ]
                , text " "
                , b [ ariaHidden True ] [ text (Eos.symbolToSymbolCodeString community.symbol) ]
                ]
            , img
                [ src "/images/doggo_holding_coins.svg"
                , alt ""
                , class "absolute right-1 top-0 -translate-y-2/3"
                ]
                []
            ]
        , h2
            [ class "mt-6 lg:w-2/3 lg:mx-auto"
            , ariaLabel (t "community.objectives.objectives_and" ++ " " ++ t "community.objectives.actions")
            ]
            [ span [ ariaHidden True ] [ text <| t "community.objectives.objectives_and" ]
            , text " "
            , span [ class "font-bold", ariaHidden True ] [ text <| t "community.objectives.actions" ]
            ]
        , case community.objectives of
            RemoteData.Success objectives ->
                let
                    filteredObjectives =
                        List.filter (\objective -> not objective.isCompleted)
                            objectives
                in
                div []
                    [ if List.isEmpty filteredObjectives then
                        div [ class "lg:w-1/2 xl:w-1/3 lg:mx-auto flex flex-col items-center pt-4 pb-6" ]
                            [ img [ src "/images/doggo-laying-down.svg", alt (t "community.objectives.empty_dog_alt") ] []
                            , p [ class "mt-4 text-black font-bold" ]
                                [ text <| t "community.objectives.empty_title"
                                ]
                            , p [ class "text-center mt-4" ]
                                [ text <| t "community.objectives.empty_objectives_line_1"
                                , br [] []
                                , br [] []
                                , text <| t "community.objectives.empty_objectives_line_2"
                                ]
                            ]

                      else
                        ul [ class "space-y-4 mt-4" ]
                            (List.map
                                (viewObjective loggedIn.shared.translators model)
                                filteredObjectives
                            )
                    , intersectionObserver
                        { targetSelectors =
                            filteredObjectives
                                |> List.filter (\objective -> List.member objective.id (AssocList.keys model.shownObjectives))
                                |> List.concatMap .actions
                                |> List.filterMap
                                    (\action ->
                                        if action.isCompleted then
                                            Nothing

                                        else
                                            Just ("#" ++ actionCardId action)
                                    )
                        , threshold = 0.01
                        , breakpointToExclude = Just View.Components.Lg
                        , onStartedIntersecting = Just StartedIntersecting
                        , onStoppedIntersecting = Just StoppedIntersecting
                        }
                    , if not loggedIn.shared.canShare then
                        Form.Text.view
                            (Form.Text.init
                                { label = ""
                                , id = "share-fallback-input"
                                }
                                |> Form.Text.withExtraAttrs
                                    [ class "absolute opacity-0 left-[-9999em]"
                                    , tabindex -1
                                    , ariaHidden True
                                    ]
                                |> Form.Text.withContainerAttrs [ class "mb-0 overflow-hidden" ]
                                |> Form.Text.withInputElement (Form.Text.TextareaInput { submitOnEnter = False })
                            )
                            { onChange = \_ -> NoOp
                            , onBlur = NoOp
                            , value =
                                case model.sharingAction of
                                    Nothing ->
                                        Url.toString loggedIn.shared.url

                                    Just sharingAction ->
                                        tr
                                            "community.objectives.share_action"
                                            [ ( "community_name", community.name )
                                            , ( "objective_description", Markdown.toRawString sharingAction.objective.description )
                                            , ( "action_description", Markdown.toRawString sharingAction.description )
                                            , ( "url"
                                              , Route.WithObjectiveSelected
                                                    { id = Action.objectiveIdToInt sharingAction.objective.id
                                                    , action = Just sharingAction.id
                                                    }
                                                    |> Route.CommunityObjectives
                                                    |> Route.addRouteToUrl loggedIn.shared
                                                    |> Url.toString
                                              )
                                            ]
                            , error = text ""
                            , hasError = False
                            , translators = loggedIn.shared.translators
                            , isRequired = False
                            }

                      else
                        text ""
                    , viewClaimModal loggedIn.shared model
                    ]

            RemoteData.Loading ->
                ul [ class "space-y-4 mt-4" ]
                    (List.range 0 4
                        |> List.map (\_ -> li [ class "bg-white py-10 rounded animate-skeleton-loading lg:w-2/3 lg:mx-auto" ] [])
                    )

            RemoteData.NotAsked ->
                ul [ class "space-y-4 mt-4" ]
                    (List.range 0 4
                        |> List.map (\_ -> li [ class "bg-white py-10 rounded animate-skeleton-loading lg:w-2/3 lg:mx-auto" ] [])
                    )

            RemoteData.Failure _ ->
                div [ class "mt-4 bg-white rounded py-6 px-4 flex flex-col items-center lg:w-2/3 lg:mx-auto" ]
                    [ img
                        [ alt ""
                        , src "/images/not_found.svg"
                        , class "max-h-40"
                        ]
                        []
                    , p [ class "text-center mt-4" ]
                        [ text <| t "community.objectives.error_loading" ]
                    ]
        , div [ class "bg-white rounded p-4 pb-6 relative mt-18 lg:w-2/3 lg:mx-auto" ]
            [ p [ class "text-center mt-2" ] [ text <| t "community.objectives.visit_community_page" ]
            , a
                [ Route.href Route.CommunityAbout
                , class "button button-secondary w-full mt-4"
                ]
                [ text <| t "community.objectives.go_to_community_page" ]
            , div [ class "absolute top-0 left-0 w-full flex justify-center" ]
                [ img
                    [ src "/images/success-doggo.svg"
                    , alt ""
                    , class "-translate-y-3/4"
                    ]
                    []
                ]
            ]
        ]


viewObjective : Translation.Translators -> Model -> Community.Objective -> Html Msg
viewObjective translators model objective =
    let
        filteredActions =
            List.filter (\action -> not action.isCompleted)
                objective.actions

        isOpen =
            AssocList.get objective.id model.shownObjectives
                |> Maybe.map (\{ isClosing } -> not isClosing)
                |> Maybe.withDefault False

        isHighlighted =
            case model.highlightedAction of
                Nothing ->
                    False

                Just { objectiveId, actionId } ->
                    objectiveId == objective.id && Maybe.Extra.isNothing actionId

        maybeShownObjectivesInfo =
            AssocList.get objective.id model.shownObjectives

        visibleActionId =
            maybeShownObjectivesInfo
                |> Maybe.andThen .visibleAction

        visibleActionHeight =
            maybeShownObjectivesInfo
                |> Maybe.andThen .visibleActionHeight

        previousVisibleActionHeight =
            maybeShownObjectivesInfo
                |> Maybe.andThen .previousVisibleActionHeight

        openHeight =
            maybeShownObjectivesInfo
                |> Maybe.andThen .openHeight

        closedHeight =
            maybeShownObjectivesInfo
                |> Maybe.andThen .closedHeight
    in
    li
        []
        [ case ( openHeight, Maybe.Extra.or closedHeight visibleActionHeight ) of
            ( Just open, Just closed ) ->
                Html.node "style"
                    []
                    [ """
                    @keyframes shrink-details-{{id}} {
                        0% { height: calc({{open-height}}px - 16px); }
                        100% { height: {{closed-height}}px; }
                    }
                    """
                        |> String.replace "{{id}}" (String.fromInt (Action.objectiveIdToInt objective.id))
                        |> String.replace "{{open-height}}" (String.fromFloat open)
                        |> String.replace "{{closed-height}}" (String.fromFloat closed)
                        |> text
                    ]

            _ ->
                text ""
        , details
            [ id (objectiveDetailsId objective)
            , if isOpen then
                Html.Attributes.attribute "open" "true"

              else
                class ""
            , style "animation-duration" "300ms"
            , style "animation-timing-function" "ease-in-out"
            , if isOpen then
                class ""

              else
                style "animation-name" ("shrink-details-" ++ String.fromInt (Action.objectiveIdToInt objective.id))
            , Html.Events.on "animationend"
                (Decode.field "animationName" Decode.string
                    |> Decode.andThen
                        (\animationName ->
                            if animationName == "shrink-details-" ++ String.fromInt (Action.objectiveIdToInt objective.id) then
                                Decode.succeed (FinishedClosingObjective objective)

                            else
                                Decode.fail "animationName did not match"
                        )
                )
            ]
            [ summary
                [ id (objectiveSummaryId objective)
                , class "marker-hidden lg:w-2/3 lg:mx-auto focus-ring rounded"
                , classList [ ( "border border-green ring ring-green ring-opacity-30", isHighlighted ) ]
                , role "button"
                , ariaHasPopup "true"
                , onClick (ClickedToggleObjectiveVisibility objective)
                ]
                [ div
                    [ class "flex marker-hidden items-center bg-white rounded px-4 py-6 cursor-pointer"
                    ]
                    [ Icons.cambiatusCoin "text-blue fill-current flex-shrink-0 self-start mt-1"
                    , h3 [ title (Markdown.toRawString objective.description) ]
                        [ Markdown.view [ class "font-bold px-4 line-clamp-4 self-start mt-1" ] objective.description ]
                    , span
                        [ class "ml-auto flex-shrink-0 transition-transform duration-150 motion-reduce:transition-none"
                        , classList
                            [ ( "rotate-180", isOpen )
                            , ( "rotate-0", not isOpen )
                            ]
                        ]
                        [ Icons.arrowDown "text-gray-900 fill-current"
                        ]
                    ]
                ]
            , div
                [ case visibleActionHeight of
                    Nothing ->
                        case previousVisibleActionHeight of
                            Nothing ->
                                class ""

                            Just height ->
                                style "height"
                                    ("calc(" ++ String.fromInt (ceiling height) ++ "px + 32px)")

                    Just height ->
                        style "height"
                            (max (ceiling height)
                                (ceiling <| Maybe.withDefault 0 previousVisibleActionHeight)
                                |> String.fromInt
                                |> (\heightString -> "calc(" ++ heightString ++ "px + 32px")
                            )
                , class "overflow-y-hidden duration-300 ease-in-out origin-top motion-reduce:transition-none"
                , classList [ ( "transition-all", Maybe.Extra.isJust visibleActionHeight ) ]
                ]
                [ div
                    [ class "duration-300 ease-in-out origin-top lg:!h-full motion-reduce:transition-none"
                    , classList
                        [ ( "lg:scale-0", not isOpen )
                        , ( "lg:scale-1", isOpen )
                        , ( "transition-transform", Maybe.Extra.isNothing visibleActionHeight )
                        ]
                    ]
                    [ if not isOpen then
                        text ""

                      else if List.isEmpty filteredActions then
                        div
                            [ class "lg:w-1/2 xl:w-1/3 lg:mx-auto flex flex-col items-center pt-4 pb-6 animate-fade-in-from-above"
                            , Html.Events.on "animationend" (Decode.succeed (FinishedOpeningActions objective))
                            , Html.Events.on "animationcancel" (Decode.succeed (FinishedOpeningActions objective))
                            ]
                            [ img
                                [ src "/images/doggo-laying-down.svg"
                                , alt (translators.t "community.objectives.empty_dog_alt")
                                ]
                                []
                            , p [ class "mt-4 text-black font-bold text-center" ]
                                [ text <| translators.t "community.objectives.empty_title" ]
                            , p [ class "text-center mt-4" ]
                                [ text <| translators.t "community.objectives.empty_line_1"
                                , br [] []
                                , br [] []
                                , text <| translators.tr "community.objectives.empty_line_2" [ ( "symbol", Eos.symbolToSymbolCodeString objective.community.symbol ) ]
                                ]
                            ]

                      else
                        View.Components.masonryLayout
                            [ View.Components.Lg, View.Components.Xl ]
                            { transitionWithParent =
                                case model.highlightedAction of
                                    Nothing ->
                                        True

                                    Just { objectiveId } ->
                                        objectiveId /= objective.id
                            }
                            [ class "mt-4 mb-2 flex h-full overflow-y-hidden overflow-x-scroll snap-x scrollbar-hidden gap-4 transition-all lg:gap-x-6 lg:overflow-visible lg:-mb-4"
                            , classList
                                [ ( "lg:grid-cols-1 lg:w-1/2 lg:mx-auto xl:w-1/3", List.length filteredActions == 1 )
                                , ( "lg:grid-cols-2 xl:grid-cols-2 xl:w-2/3 xl:mx-auto", List.length filteredActions == 2 )
                                , ( "lg:grid-cols-2 xl:grid-cols-3", List.length filteredActions > 2 )
                                ]
                            , id (objectiveContainerId objective)
                            , role "list"
                            ]
                            (List.indexedMap
                                (viewAction translators model objective)
                                filteredActions
                            )
                    ]
                ]
            , div [ class "flex justify-center gap-2 lg:hidden" ]
                (filteredActions
                    |> List.indexedMap
                        (\index action ->
                            button
                                [ class "border border-gray-900 rounded-full w-3 h-3 transition-colors focus-ring"
                                , classList
                                    [ ( "border-orange-300 bg-orange-300", Just action.id == visibleActionId )
                                    , ( "hover:bg-orange-300/50 hover:border-orange-300/50", Just action.id /= visibleActionId )
                                    ]
                                , id ("go-to-action-" ++ String.fromInt action.id)
                                , onClick (ClickedScrollToAction action)
                                , ariaLabel <|
                                    translators.tr "community.objectives.go_to_action"
                                        [ ( "index"
                                          , String.fromInt (index + 1)
                                          )
                                        ]
                                , role "link"
                                ]
                                []
                        )
                )
            ]
        ]


viewAction : Translation.Translators -> Model -> Community.Objective -> Int -> Action -> Html Msg
viewAction ({ t } as translators) model objective index action =
    let
        isHighlighted =
            case model.highlightedAction of
                Nothing ->
                    False

                Just { actionId } ->
                    actionId == Just action.id
    in
    li
        [ class "bg-white rounded self-start w-full flex-shrink-0 snap-center snap-always mb-6 animate-fade-in-from-above motion-reduce:animate-none"
        , classList [ ( "border border-green ring ring-green ring-opacity-30", isHighlighted ) ]
        , style "animation-delay" ("calc(75ms * " ++ String.fromInt index ++ ")")
        , id (actionCardId action)
        , Html.Events.on "animationend" (Decode.succeed (FinishedOpeningActions objective))
        ]
        [ case action.image of
            Nothing ->
                text ""

            Just "" ->
                text ""

            Just image ->
                div [ class "mt-2 mx-2 relative" ]
                    [ img [ src image, alt "", class "rounded" ] []
                    , div [ class "bg-gradient-to-t from-[#01003a14] to-[#01003a00] absolute top-0 left-0 w-full h-full rounded" ] []
                    ]
        , div [ class "px-4 pt-4 pb-6" ]
            [ div [ class "flex" ]
                [ span
                    [ class "text-lg text-gray-500 font-bold"
                    , ariaHidden True
                    ]
                    [ text (String.fromInt (index + 1)), text "." ]
                , div [ class "ml-5 mt-1 min-w-0 w-full" ]
                    [ h4 [ title (Markdown.toRawString action.description) ]
                        [ Markdown.view [ class "line-clamp-3 hide-children-from-2" ] action.description ]
                    , span [ class "sr-only" ]
                        [ text <|
                            t "community.objectives.reward"
                                ++ ": "
                                ++ Eos.assetToString translators
                                    { amount = action.reward
                                    , symbol = action.objective.community.symbol
                                    }
                        ]
                    , span
                        [ class "font-bold text-sm text-gray-900 uppercase block mt-6"
                        , ariaHidden True
                        ]
                        [ text <| t "community.objectives.reward" ]
                    , div
                        [ class "mt-1 text-green font-bold"
                        , ariaHidden True
                        ]
                        [ span [ class "text-2xl mr-1" ]
                            [ text
                                (Eos.formatSymbolAmount
                                    translators
                                    action.objective.community.symbol
                                    action.reward
                                )
                            ]
                        , text (Eos.symbolToSymbolCodeString action.objective.community.symbol)
                        ]
                    ]
                ]
            , div
                [ class "grid grid-cols-1 sm:grid-cols-2 gap-x-4 gap-y-2 mt-6"
                , classList [ ( "sm:grid-cols-1", not (Action.isClaimable action) ) ]
                ]
                [ button
                    [ class "button button-secondary w-full"
                    , onClick (ClickedShareAction action)
                    , id (shareActionButtonId action.id)
                    ]
                    [ Icons.share "mr-2 flex-shrink-0"
                    , text <| t "share"
                    ]
                , if Action.isClaimable action then
                    button
                        [ class "button button-primary w-full sm:col-span-1"
                        , onClick (ClickedClaimAction { position = index + 1, action = action })
                        ]
                        [ if action.hasProofPhoto then
                            Icons.camera "w-4 mr-2 flex-shrink-0"

                          else
                            text ""
                        , text <| t "dashboard.claim"
                        ]

                  else
                    text ""
                ]
            ]
        ]


viewClaimModal : Shared -> Model -> Html Msg
viewClaimModal ({ translators } as shared) model =
    case model.claimingStatus of
        NotClaiming ->
            text ""

        Claiming { position, action, proof } ->
            let
                { t } =
                    translators

                ( onClaimClick, isClaimDisabled ) =
                    case proof of
                        WithProof formModel _ ->
                            ( Form.parse (claimWithPhotoForm translators)
                                formModel
                                { onError = GotPhotoProofFormMsg
                                , onSuccess = ConfirmedClaimActionWithPhotoProof
                                }
                            , Form.hasFieldsLoading formModel
                            )

                        NoProofNecessary ->
                            ( ConfirmedClaimAction, False )
            in
            View.Modal.initWith
                { closeMsg = ClickedCloseClaimModal
                , isVisible = True
                }
                |> View.Modal.withBody
                    [ case action.image of
                        Nothing ->
                            text ""

                        Just "" ->
                            text ""

                        Just image ->
                            div [ class "mb-4 relative" ]
                                [ img
                                    [ src image
                                    , alt ""
                                    , class "max-w-full mx-auto object-scale-down rounded"
                                    ]
                                    []
                                , div [ class "bg-gradient-to-t from-[#01003a14] to-[#01003a00] absolute top-0 left-0 w-full h-full rounded" ] []
                                ]
                    , div
                        [ class "flex"
                        , classList [ ( "md:mb-6", proof == NoProofNecessary ) ]
                        ]
                        [ span [ class "text-lg text-gray-500 font-bold" ] [ text (String.fromInt position ++ ".") ]
                        , div [ class "ml-5 mt-1 min-w-0 w-full" ]
                            [ Markdown.view [] action.description
                            , div [ class "md:flex md:justify-between md:w-full" ]
                                [ div []
                                    [ span [ class "font-bold text-sm text-gray-900 uppercase block mt-6" ]
                                        [ text <| t "community.objectives.reward" ]
                                    , div [ class "text-green font-bold" ]
                                        [ span [ class "text-2xl mr-1" ]
                                            [ text
                                                (Eos.formatSymbolAmount translators
                                                    action.objective.community.symbol
                                                    action.reward
                                                )
                                            ]
                                        , text (Eos.symbolToSymbolCodeString action.objective.community.symbol)
                                        ]
                                    ]
                                , viewClaimCount translators [ class "hidden md:flex md:self-end md:mr-8" ] action
                                ]
                            ]
                        ]
                    , viewClaimCount translators
                        [ class "md:hidden"
                        , classList [ ( "mb-6", proof == NoProofNecessary ) ]
                        ]
                        action
                    , case proof of
                        WithProof formModel proofCode ->
                            let
                                timeLeft =
                                    case proofCode of
                                        NoCodeNecessary ->
                                            Nothing

                                        GeneratingCode ->
                                            Nothing

                                        WithCode { expiration } ->
                                            let
                                                minutes =
                                                    Time.Extra.diff Time.Extra.Minute
                                                        shared.timezone
                                                        shared.now
                                                        expiration

                                                seconds =
                                                    Time.Extra.diff Time.Extra.Second
                                                        shared.timezone
                                                        shared.now
                                                        expiration
                                                        |> modBy 60
                                            in
                                            Just { minutes = minutes, seconds = seconds }

                                isTimeOver =
                                    case timeLeft of
                                        Nothing ->
                                            False

                                        Just { minutes } ->
                                            minutes < 0
                            in
                            div []
                                [ p [ class "text-lg font-bold text-gray-333 mt-6 mb-4 md:text-center" ]
                                    [ text <| t "community.actions.proof.title" ]
                                , case action.photoProofInstructions of
                                    Just instructions ->
                                        Markdown.view [] instructions

                                    Nothing ->
                                        p [] [ text <| t "community.actions.proof.upload_hint" ]
                                , case proofCode of
                                    NoCodeNecessary ->
                                        text ""

                                    GeneratingCode ->
                                        div [ class "p-4 mt-4 bg-gray-100 rounded-sm flex flex-col items-center justify-center md:w-1/2 md:mx-auto" ]
                                            [ span [ class "uppercase text-gray-333 font-bold text-sm" ]
                                                [ text <| t "community.actions.form.verification_code" ]
                                            , span [ class "bg-gray-333 animate-skeleton-loading h-10 w-44 mt-2" ] []
                                            ]

                                    WithCode { code } ->
                                        div []
                                            [ div [ class "p-4 mt-4 bg-gray-100 rounded-sm flex flex-col items-center justify-center md:w-1/2 md:mx-auto" ]
                                                [ span [ class "uppercase text-gray-333 font-bold text-sm" ]
                                                    [ text <| t "community.actions.form.verification_code" ]
                                                , span [ class "font-bold text-xl text-gray-333" ] [ text code ]
                                                ]
                                            , p
                                                [ class "text-purple-500 text-center mt-4"
                                                , classList [ ( "text-red", isTimeOver ) ]
                                                ]
                                                [ text <| t "community.actions.proof.code_period_label"
                                                , text " "
                                                , span [ class "font-bold" ]
                                                    [ case timeLeft of
                                                        Nothing ->
                                                            text "30:00"

                                                        Just { minutes, seconds } ->
                                                            (Utils.padInt 2 minutes ++ ":" ++ Utils.padInt 2 seconds)
                                                                |> text
                                                    ]
                                                ]
                                            ]
                                , Form.viewWithoutSubmit [ class "mb-6" ]
                                    translators
                                    (\_ -> [])
                                    (claimWithPhotoForm translators)
                                    formModel
                                    { toMsg = GotPhotoProofFormMsg }
                                ]

                        NoProofNecessary ->
                            text ""
                    ]
                |> View.Modal.withFooter
                    [ div [ class "w-full grid md:grid-cols-2 gap-4" ]
                        [ if Action.isClaimable action then
                            button
                                [ class "button button-secondary w-full"
                                , onClick ClickedCloseClaimModal
                                ]
                                [ text <| t "menu.cancel" ]

                          else
                            text ""
                        , button
                            [ onClick onClaimClick
                            , class "button button-primary w-full"
                            , disabled isClaimDisabled
                            ]
                            [ text <| t "dashboard.claim" ]
                        ]
                    ]
                |> View.Modal.withSize View.Modal.FullScreen
                |> View.Modal.toHtml


viewClaimCount : Translation.Translators -> List (Html.Attribute msg) -> Action -> Html msg
viewClaimCount { t, tr } attrs action =
    div
        (class "mt-4 p-2 bg-gray-100 flex items-center justify-center text-gray-900 font-semibold text-sm rounded-sm"
            :: attrs
        )
        [ img
            [ src "/images/doggo_holding_coins.svg"
            , alt ""
            , class "w-8 mr-2"
            ]
            []
        , p []
            [ text <| t "community.objectives.claim_count"
            , text " "
            , span [ class "text-base ml-1 font-bold" ]
                [ if action.claimCount == 1 then
                    text <| t "community.objectives.claim_count_times_singular"

                  else
                    text <|
                        tr "community.objectives.claim_count_times"
                            [ ( "count", String.fromInt action.claimCount ) ]
                ]
            ]
        ]


claimWithPhotoForm : Translation.Translators -> Form.Form msg Form.File.SingleModel String
claimWithPhotoForm translators =
    Form.succeed identity
        |> Form.with
            (Form.File.init { id = "photo-proof-input" }
                |> Form.File.withFileTypes [ Form.File.Image, Form.File.Pdf ]
                |> Form.File.withContainerAttributes [ class "w-full bg-gray-100 grid place-items-center mt-2" ]
                |> Form.File.withEntryContainerAttributes (\_ -> [ class "h-56 rounded-sm overflow-hidden w-full grid place-items-center" ])
                |> Form.File.withImageClass "h-56"
                |> Form.File.withAddImagesView
                    [ div [ class "w-full h-56 bg-gray-100 rounded-sm flex flex-col justify-center items-center" ]
                        [ Icons.addPhoto "fill-current text-body-black w-10 mb-2"
                        , p [ class "px-4 font-bold" ] [ text <| translators.t "community.actions.proof.upload_hint" ]
                        ]
                    ]
                |> Form.File.withAddImagesContainerAttributes [ class "!w-full rounded-sm" ]
                |> Form.File.withImageCropperAttributes [ class "rounded-sm" ]
                |> Form.file
                    { parser = Ok
                    , translators = translators
                    , value = identity
                    , update = \newModel _ -> newModel
                    , externalError = always Nothing
                    }
            )



-- UTILS


generateProofCode : Action -> String -> Time.Posix -> String
generateProofCode action claimerAccountUint64 time =
    (String.fromInt action.id
        ++ claimerAccountUint64
        ++ String.fromInt (Time.posixToMillis time // 1000)
    )
        |> Sha256.sha256
        |> String.slice 0 8


objectiveDetailsId : { objective | id : Action.ObjectiveId } -> String
objectiveDetailsId objective =
    "objective-details-" ++ String.fromInt (Action.objectiveIdToInt objective.id)


objectiveSummaryId : { objective | id : Action.ObjectiveId } -> String
objectiveSummaryId objective =
    "objective-summary-" ++ String.fromInt (Action.objectiveIdToInt objective.id)


objectiveContainerId : { objective | id : Action.ObjectiveId } -> String
objectiveContainerId objective =
    "objective-container-" ++ String.fromInt (Action.objectiveIdToInt objective.id)


actionCardId : Action -> String
actionCardId action =
    "action-card-" ++ String.fromInt action.id


shareActionButtonId : Int -> String
shareActionButtonId actionId =
    "share-action-button-" ++ String.fromInt actionId


idFromActionCardId : String -> Maybe Int
idFromActionCardId elementId =
    -- Remove the leading "action-card-"
    String.dropLeft 12 elementId
        |> String.toInt


receiveBroadcast : LoggedIn.BroadcastMsg -> Maybe Msg
receiveBroadcast broadcastMsg =
    case broadcastMsg of
        LoggedIn.CommunityFieldLoaded _ (Community.ObjectivesValue objectives) ->
            Just (CompletedLoadObjectives objectives)

        _ ->
            Nothing


jsAddressToMsg : List String -> Encode.Value -> Maybe Msg
jsAddressToMsg addr val =
    let
        decodeConfirmedClaimAction =
            Decode.decodeValue (Decode.field "transactionId" Decode.string) val
                |> Result.map (\_ -> ())
                |> Result.mapError (\_ -> val)
                |> CompletedClaimingAction
                |> Just
    in
    case addr of
        "ClickedShareAction" :: _ ->
            case
                Decode.decodeValue
                    (Decode.map2
                        (\hasCopied actionId ->
                            if hasCopied then
                                Just actionId

                            else
                                Nothing
                        )
                        (Decode.field "copied" Decode.bool)
                        (Decode.field "addressData" Decode.int)
                    )
                    val
            of
                Ok (Just actionId) ->
                    Just (CopiedShareLinkToClipboard actionId)

                Ok Nothing ->
                    Just NoOp

                Err _ ->
                    Just NoOp

        "CompletedLoadObjectives" :: _ ->
            Decode.decodeValue (Decode.field "uint64name" Decode.string) val
                |> Result.map GotUint64Name
                |> Result.toMaybe

        "ClickedClaimAction" :: _ ->
            Decode.decodeValue (Decode.field "uint64name" Decode.string) val
                |> Result.map GotUint64Name
                |> Result.toMaybe

        "ConfirmedClaimAction" :: _ ->
            decodeConfirmedClaimAction

        "ConfirmedClaimActionWithPhotoProof" :: _ ->
            decodeConfirmedClaimAction

        _ ->
            Nothing


msgToString : Msg -> List String
msgToString msg =
    case msg of
        NoOp ->
            [ "NoOp" ]

        CompletedLoadObjectives _ ->
            [ "CompletedLoadObjectives" ]

        ClickedToggleObjectiveVisibility _ ->
            [ "ClickedToggleObjectiveVisibility" ]

        FinishedOpeningActions _ ->
            [ "FinishedOpeningActions" ]

        FinishedClosingObjective _ ->
            [ "FinishedClosingObjective" ]

        GotObjectiveDetailsHeight _ _ ->
            [ "GotObjectiveDetailsHeight" ]

        GotObjectiveSummaryHeight _ _ ->
            [ "GotObjectiveSummaryHeight" ]

        GotVisibleActionViewport _ _ ->
            [ "GotVisibleActionViewport" ]

        ClickedScrollToAction _ ->
            [ "ClickedScrollToAction" ]

        ClickedShareAction _ ->
            [ "ClickedShareAction" ]

        ClickedClaimAction _ ->
            [ "ClickedClaimAction" ]

        ClickedCloseClaimModal ->
            [ "ClickedCloseClaimModal" ]

        StartedIntersecting _ ->
            [ "StartedIntersecting" ]

        StoppedIntersecting _ ->
            [ "StoppedIntersecting" ]

        ConfirmedClaimAction ->
            [ "ConfirmedClaimAction" ]

        ConfirmedClaimActionWithPhotoProof _ ->
            [ "ConfirmedClaimActionWithPhotoProof" ]

        GotPhotoProofFormMsg _ ->
            [ "GotPhotoProofFormMsg" ]

        GotUint64Name _ ->
            [ "GotUint64Name" ]

        CompletedClaimingAction r ->
            [ "CompletedClaimingAction", UR.resultToString r ]

        CopiedShareLinkToClipboard _ ->
            [ "CopiedShareLinkToClipboard" ]
