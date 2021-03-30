module Session.LoggedIn exposing
    ( External(..)
    , ExternalMsg(..)
    , FeatureStatus(..)
    , Model
    , Msg(..)
    , Page(..)
    , ProfileStatus(..)
    , addCommunity
    , addNotification
    , askedAuthentication
    , init
    , initLogin
    , isAccount
    , isActive
    , isAuth
    , jsAddressToMsg
    , mapExternal
    , maybePrivateKey
    , msgToString
    , profile
    , readAllNotifications
    , showContactModal
    , showFeedback
    , subscriptions
    , update
    , view
    , viewFooter
    )

import Action
import Api
import Api.Graphql
import Auth
import Avatar
import Browser.Dom as Dom
import Browser.Events
import Cambiatus.Object
import Cambiatus.Object.UnreadNotifications
import Cambiatus.Subscription as Subscription
import Community
import Eos exposing (Symbol)
import Eos.Account as Eos
import Flags exposing (Flags)
import Graphql.Document
import Graphql.Http
import Graphql.Operation exposing (RootSubscription)
import Graphql.SelectionSet exposing (SelectionSet)
import Html exposing (Html, a, button, div, footer, img, nav, p, span, text)
import Html.Attributes exposing (class, classList, src, style, type_)
import Html.Events exposing (onClick, onMouseEnter)
import Http
import I18Next exposing (Delims(..), Translations)
import Icons
import Json.Decode as Decode exposing (Value)
import Json.Encode as Encode exposing (Value)
import List.Extra as List
import Notification exposing (Notification)
import Ports
import Profile exposing (Model)
import Profile.Contact as Contact
import RemoteData exposing (RemoteData)
import Route exposing (Route)
import Search exposing (State(..))
import Session.Shared as Shared exposing (Shared)
import Shop
import Task
import Time exposing (Posix)
import Translation
import UpdateResult as UR
import View.Feedback as Feedback
import View.Modal as Modal



-- INIT


{-| Initialize already logged in user when the page is [re]loaded.
-}
init : Shared -> Eos.Name -> Flags -> String -> ( Model, Cmd Msg )
init shared accountName flags authToken =
    let
        authModel =
            Auth.init shared
    in
    ( initModel shared authModel accountName flags.selectedCommunity authToken
    , Cmd.batch
        [ Api.Graphql.query shared (Just authToken) (Profile.query accountName) CompletedLoadProfile
        , Api.Graphql.query shared (Just authToken) (Community.settingsQuery flags.selectedCommunity) CompletedLoadSettings
        , Ports.getRecentSearches () -- run on the page refresh, duplicated in `initLogin`
        , Task.perform GotTime Time.now
        ]
    )


fetchTranslations : String -> Shared -> Cmd Msg
fetchTranslations language _ =
    CompletedLoadTranslation language
        |> Translation.get language


{-| Initialize logged in user after signing-in.
-}
initLogin : Shared -> Auth.Model -> Profile.Model -> String -> ( Model, Cmd Msg )
initLogin shared authModel profile_ authToken =
    let
        selectedCommunity : Symbol
        selectedCommunity =
            List.head profile_.communities
                |> Maybe.map .id
                |> Maybe.withDefault Eos.cambiatusSymbol

        model =
            initModel shared authModel profile_.account selectedCommunity authToken
    in
    ( { model
        | profile = Loaded profile_
      }
    , Cmd.batch
        [ Task.perform
            (\_ -> SelectCommunity selectedCommunity Cmd.none)
            (Task.succeed ())
        , Ports.getRecentSearches () -- run on the passphrase login, duplicated in `init`
        ]
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map GotAuthMsg (Auth.subscriptions model.auth)
        , Sub.map KeyDown (Browser.Events.onKeyDown (Decode.field "key" Decode.string))
        , Sub.map GotSearchMsg Search.subscriptions
        , Sub.map GotActionMsg (Action.subscriptions model.claimingAction)
        ]



-- MODEL


type alias Model =
    { shared : Shared
    , accountName : Eos.Name
    , profile : ProfileStatus
    , selectedCommunity : Symbol
    , showUserNav : Bool
    , showLanguageItems : Bool
    , showNotificationModal : Bool
    , showMainNav : Bool
    , notification : Notification.Model
    , unreadCount : Int
    , showAuthModal : Bool
    , auth : Auth.Model
    , showCommunitySelector : Bool
    , feedback : Feedback.Model
    , hasShop : FeatureStatus
    , hasObjectives : FeatureStatus
    , hasKyc : FeatureStatus
    , contactModel : Contact.Model
    , showContactModal : Bool
    , searchModel : Search.Model
    , claimingAction : Action.Model
    , date : Maybe Posix
    , authToken : String
    }


type FeatureStatus
    = FeatureLoaded Bool
    | FeatureLoading


initModel : Shared -> Auth.Model -> Eos.Name -> Symbol -> String -> Model
initModel shared authModel accountName selectedCommunity authToken =
    { shared = shared
    , accountName = accountName
    , profile = Loading accountName
    , selectedCommunity = selectedCommunity
    , showUserNav = False
    , showLanguageItems = False
    , showNotificationModal = False
    , showMainNav = False
    , notification = Notification.init
    , unreadCount = 0
    , showAuthModal = False
    , auth = authModel
    , feedback = Feedback.Hidden
    , showCommunitySelector = False
    , hasShop = FeatureLoading
    , hasObjectives = FeatureLoading
    , hasKyc = FeatureLoading
    , contactModel = Contact.initSingle
    , showContactModal = False
    , searchModel = Search.init selectedCommunity
    , claimingAction = { status = Action.NotAsked, feedback = Nothing, needsPinConfirmation = False }
    , date = Nothing
    , authToken = authToken
    }


type ProfileStatus
    = Loading Eos.Name
    | LoadingFailed Eos.Name (Graphql.Http.Error (Maybe Profile.Model))
    | Loaded Profile.Model


isAuth : Model -> Bool
isAuth model =
    Auth.isAuth model.auth


maybePrivateKey : Model -> Maybe String
maybePrivateKey model =
    Auth.maybePrivateKey model.auth



-- VIEW


type Page
    = Other
    | Dashboard
    | Communities
    | Community
    | CommunitySettings
    | CommunitySettingsFeatures
    | CommunityEditor
    | Objectives
    | ObjectiveEditor
    | ActionEditor
    | Claim
    | News
    | Learn
    | Notification
    | Shop
    | ShopEditor
    | ShopViewer
    | FAQ
    | Profile
    | ProfilePublic
    | ProfileEditor
    | ProfileAddKyc
    | ProfileClaims
    | ProfileAddContact
    | PaymentHistory
    | Transfer
    | ViewTransfer
    | Analysis


view : (Msg -> msg) -> Page -> Model -> Html msg -> Html msg
view thisMsg page ({ shared } as model) content =
    case ( Shared.translationStatus shared, model.profile ) of
        ( Shared.LoadingTranslation, _ ) ->
            Shared.viewFullLoading

        ( Shared.LoadingTranslationFailed err, _ ) ->
            Shared.viewFullError shared
                err
                ClickedTryAgainTranslation
                "An error occurred while loading translation."
                |> Html.map thisMsg

        ( _, Loading _ ) ->
            Shared.viewFullLoading

        ( _, LoadingFailed accountName err ) ->
            Shared.viewFullGraphqlError shared
                err
                (ClickedTryAgainProfile accountName)
                "An error occurred while loading profile."
                |> Html.map thisMsg

        ( _, Loaded profile_ ) ->
            viewHelper thisMsg page profile_ model content


viewHelper : (Msg -> pageMsg) -> Page -> Profile.Model -> Model -> Html pageMsg -> Html pageMsg
viewHelper pageMsg page profile_ ({ shared } as model) content =
    let
        { t } =
            shared.translators
    in
    div
        [ class "min-h-screen flex flex-col" ]
        ([ div [ class "bg-white" ]
            [ div [ class "container mx-auto" ]
                [ viewHeader model profile_
                    |> Html.map pageMsg
                , if Search.isActive model.searchModel then
                    text ""

                  else
                    viewMainMenu page model |> Html.map pageMsg
                ]
            , Feedback.view model.feedback
                |> Html.map (GotFeedbackMsg >> pageMsg)
            ]
         ]
            ++ (let
                    viewClaimWithProofs action proof =
                        [ Action.viewClaimWithProofs proof shared.translators (isAuth model) action
                            |> Html.map (GotActionMsg >> pageMsg)
                        ]
                in
                case ( Search.isActive model.searchModel, model.claimingAction.status ) of
                    ( True, _ ) ->
                        [ Search.viewSearchBody
                            shared.translators
                            model.selectedCommunity
                            model.date
                            (GotSearchMsg >> pageMsg)
                            (GotActionMsg >> pageMsg)
                            model.searchModel
                        ]

                    ( False, Action.PhotoUploaderShowed action p ) ->
                        viewClaimWithProofs action p

                    ( False, Action.ClaimInProgress action (Just p) ) ->
                        viewClaimWithProofs action p

                    _ ->
                        viewPageBody model profile_ page content
               )
            ++ [ viewFooter shared
               , Action.viewClaimConfirmation shared.translators model.claimingAction
                    |> Html.map (GotActionMsg >> pageMsg)
               , Modal.initWith
                    { closeMsg = ClosedAuthModal
                    , isVisible = model.showAuthModal
                    }
                    |> Modal.withBody
                        (Auth.view True shared model.auth
                            |> List.map (Html.map GotAuthMsg)
                        )
                    |> Modal.toHtml
                    |> Html.map pageMsg
               , communitySelectorModal model
                    |> Html.map pageMsg
               , addContactModal model
                    |> Html.map pageMsg
               ]
        )


viewPageBody : Model -> Profile.Model -> Page -> Html pageMsg -> List (Html pageMsg)
viewPageBody ({ shared } as model) profile_ page content =
    let
        { t } =
            shared.translators

        hasUserKycFilled =
            case profile_.kyc of
                Just _ ->
                    True

                Nothing ->
                    False

        availableWithoutKyc : List Page
        availableWithoutKyc =
            [ Other
            , Profile
            , Notification
            , ProfilePublic
            , ProfileEditor
            , ProfileAddKyc
            , PaymentHistory
            , ViewTransfer
            ]

        viewKycRestriction =
            div [ class "mx-auto container max-w-sm" ]
                [ div [ class "my-6 mx-4 text-center" ]
                    [ p [ class "text-2xl font-bold" ]
                        [ text (t "community.kyc.restriction.title") ]
                    , p [ class "mt-2 mb-6" ]
                        [ text (t "community.kyc.restriction.description") ]
                    , a
                        [ class "button button-primary m-auto w-full sm:w-56"
                        , Route.href Route.ProfileAddKyc
                        ]
                        [ text (t "community.kyc.restriction.link") ]
                    ]
                , img
                    [ class "w-full mx-auto md:w-64 mt-6 mb-8"
                    , src "/images/not_found.svg"
                    ]
                    []
                ]
    in
    [ div [ class "flex-grow flex flex-col" ]
        [ case model.hasKyc of
            FeatureLoading ->
                div [ class "full-spinner-container h-full" ]
                    [ div [ class "spinner spinner--delay mt-8" ] [] ]

            FeatureLoaded isKycEnabled ->
                let
                    isContentAllowed =
                        List.member page availableWithoutKyc
                            || not isKycEnabled
                            || (isKycEnabled && hasUserKycFilled)
                in
                if isContentAllowed then
                    content

                else
                    viewKycRestriction
        ]
    ]


viewHeader : Model -> Profile.Model -> Html Msg
viewHeader ({ shared } as model) profile_ =
    let
        text_ str =
            text (shared.translators.t str)

        tr str values =
            shared.translators.tr str values
    in
    div [ class "flex flex-wrap items-center justify-between px-4 pt-6 pb-4" ]
        [ viewCommunitySelector model
        , div [ class "order-last w-full md:order-none mt-2 md:ml-2 md:flex-grow md:w-auto" ]
            [ Search.viewForm shared.translators model.searchModel
                |> Html.map GotSearchMsg
            ]
        , div [ class "flex items-center float-right" ]
            [ a
                [ class "outline-none relative mx-6"
                , Route.href Route.Notification
                ]
                [ Icons.notification "fill-current text-black"
                , if model.unreadCount > 0 then
                    div [ class "absolute top-0 right-0 -mr-4 px-2 py-1 bg-orange-500 text-white font-medium text-xs rounded-full" ]
                        [ text (String.fromInt model.unreadCount) ]

                  else
                    text ""
                ]
            , div [ class "relative z-20" ]
                [ button
                    [ class "h-12 z-10 bg-gray-200 py-2 px-3 relative hidden lg:visible lg:flex"
                    , classList [ ( "rounded-tr-lg rounded-tl-lg", model.showUserNav ) ]
                    , classList [ ( "rounded-lg", not model.showUserNav ) ]
                    , type_ "button"
                    , onClick (ShowUserNav (not model.showUserNav))
                    , onMouseEnter (ShowUserNav True)
                    ]
                    [ Avatar.view profile_.avatar "h-8 w-8"
                    , div [ class "flex flex-wrap text-left pl-2" ]
                        [ p [ class "w-full font-sans uppercase text-gray-900 text-xs overflow-x-hidden" ]
                            [ text (tr "menu.welcome_message" [ ( "user_name", Eos.nameToString profile_.account ) ]) ]
                        , p [ class "w-full font-sans text-indigo-500 text-sm" ]
                            [ text (shared.translators.t "menu.my_account") ]
                        ]
                    , Icons.arrowDown "float-right"
                    ]
                , button
                    [ class "h-12 z-10 py-2 px-3 flex relative lg:hidden"
                    , classList [ ( "rounded-tr-lg rounded-tl-lg", model.showUserNav ) ]
                    , classList [ ( "rounded-lg", not model.showUserNav ) ]
                    , type_ "button"
                    , onClick (ShowUserNav (not model.showUserNav))
                    , onMouseEnter (ShowUserNav True)
                    ]
                    [ Avatar.view profile_.avatar "h-8 w-8"
                    ]

                -- Invisible button to hide menu when clicking outside
                , if model.showUserNav then
                    button
                        [ class "fixed h-full w-full inset-0 bg-black opacity-50 cursor-default"
                        , onClick (ShowUserNav False)
                        , onMouseEnter (ShowUserNav False)
                        ]
                        []

                  else
                    text ""
                , nav
                    [ class "absolute right-0 lg:w-full py-2 px-4 shadow-lg bg-white rounded-t-lg rounded-b-lg lg:rounded-t-none"
                    , classList
                        [ ( "hidden", not model.showUserNav )
                        ]
                    ]
                    [ a
                        [ class "flex block w-full px-4 py-4 justify-start items-center text-sm"
                        , Route.href Route.Profile
                        , onClick (ShowUserNav False)
                        , onClick SearchClosed
                        ]
                        [ Icons.profile "mr-4"
                        , text_ "menu.profile"
                        ]
                    , button
                        [ class "flex block w-full px-4 py-4 justify-start items-center text-sm border-t"
                        , onClick ToggleLanguageItems
                        ]
                        [ Icons.languages "mr-4"
                        , text_ "menu.languages"
                        ]
                    , if model.showLanguageItems then
                        div [ class "ml-10 mb-2" ]
                            (button
                                [ class "flex block px-4 py-2 text-gray justify-between items-center text-indigo-500 font-bold text-xs"
                                ]
                                [ Shared.langFlag shared.language, text (String.toUpper shared.language) ]
                                :: Shared.viewLanguageItems shared ClickedLanguage
                            )

                      else
                        text ""
                    , button
                        [ class "flex block w-full px-4 py-4 justify-start items-center text-sm border-t"
                        , onClick ClickedLogout
                        ]
                        [ Icons.close "fill-current text-red mr-4"
                        , text_ "menu.logout"
                        ]
                    ]
                ]
            ]
        ]


viewCommunitySelector : Model -> Html Msg
viewCommunitySelector ({ shared } as model) =
    let
        findCommunity : Symbol -> Maybe Profile.CommunityInfo
        findCommunity symbol =
            case model.profile of
                Loaded p ->
                    p.communities
                        |> List.find (\c -> c.id == symbol)

                _ ->
                    Nothing

        hasMultipleCommunities : Bool
        hasMultipleCommunities =
            case model.profile of
                Loaded p ->
                    List.length p.communities > 1

                _ ->
                    False
    in
    case findCommunity model.selectedCommunity of
        Just community ->
            button [ class "flex items-center", onClick OpenCommunitySelector ]
                [ img [ class "h-10", src community.logo ] []
                , if hasMultipleCommunities then
                    Icons.arrowDown ""

                  else
                    text ""
                ]

        Nothing ->
            button [ class "flex items-center", onClick OpenCommunitySelector ]
                [ img [ class "lg:hidden h-8", src shared.logoMobile ] []
                , img
                    [ class "hidden lg:block lg:visible h-6"
                    , src shared.logo
                    ]
                    []
                ]


communitySelectorModal : Model -> Html Msg
communitySelectorModal model =
    let
        t s =
            model.shared.translators.t s

        text_ s =
            text (t s)

        viewCommunityItem : Profile.CommunityInfo -> Html Msg
        viewCommunityItem c =
            div
                [ class "flex items-center p-4 text-body cursor-pointer hover:text-black hover:bg-gray-100"
                , onClick <| SelectCommunity c.id (Route.replaceUrl model.shared.navKey Route.Dashboard)
                ]
                [ img [ src c.logo, class "h-16 w-16 mr-5 object-scale-down" ] []
                , text c.name
                ]
    in
    if model.showCommunitySelector then
        case model.profile of
            Loaded pro ->
                if List.isEmpty pro.communities then
                    text ""

                else
                    Modal.initWith
                        { closeMsg = CloseCommunitySelector
                        , isVisible = True
                        }
                        |> Modal.withHeader (t "menu.community_selector.title")
                        |> Modal.withBody
                            [ p []
                                [ text_ "menu.community_selector.body"
                                ]
                            , div [ class "w-full overflow-y-auto divide-y divide-gray-300" ]
                                (List.map viewCommunityItem pro.communities)
                            ]
                        |> Modal.toHtml

            _ ->
                text ""

    else
        text ""


addContactModal : Model -> Html Msg
addContactModal ({ contactModel, shared } as model) =
    let
        text_ s =
            shared.translators.t s
                |> text

        header =
            div [ class "mt-4" ]
                [ p [ class "inline bg-purple-100 text-white rounded-full py-0.5 px-2 text-caption uppercase" ]
                    [ text_ "contact_modal.new" ]
                , p [ class "text-heading font-bold mt-2" ]
                    [ text_ "contact_modal.title" ]
                ]

        form =
            Contact.view shared.translators contactModel
                |> Html.map GotContactMsg
    in
    Modal.initWith
        { closeMsg = ClosedAddContactModal
        , isVisible = model.showContactModal
        }
        |> Modal.withBody
            [ header
            , img [ class "mx-auto mt-10", src "/images/girl-with-phone.svg" ] []
            , form
            , p [ class "text-caption text-center uppercase my-4" ]
                [ text_ "contact_modal.footer" ]
            ]
        |> Modal.withLarge True
        |> Modal.toHtml


viewMainMenu : Page -> Model -> Html Msg
viewMainMenu page model =
    let
        menuItemClass =
            "mx-4 w-48 font-sans uppercase flex items-center justify-center leading-tight text-xs text-gray-700 hover:text-indigo-500"

        activeClass =
            "border-orange-100 border-b-2 text-indigo-500 font-medium"

        iconClass =
            "w-6 h-6 fill-current hover:text-indigo-500 mr-5"

        closeClaimWithPhoto =
            GotActionMsg Action.ClaimConfirmationClosed
    in
    nav [ class "h-16 w-full flex overflow-x-auto" ]
        [ a
            [ classList
                [ ( menuItemClass, True )
                , ( activeClass, isActive page Route.Dashboard )
                ]
            , Route.href Route.Dashboard
            , onClick closeClaimWithPhoto
            ]
            [ Icons.dashboard iconClass
            , text (model.shared.translators.t "menu.dashboard")
            ]
        , case model.hasShop of
            FeatureLoaded True ->
                a
                    [ classList
                        [ ( menuItemClass, True )
                        , ( activeClass, isActive page (Route.Shop Shop.All) )
                        ]
                    , Route.href (Route.Shop Shop.All)
                    , onClick closeClaimWithPhoto
                    ]
                    [ Icons.shop iconClass
                    , text (model.shared.translators.t "menu.shop")
                    ]

            _ ->
                text ""
        ]


isActive : Page -> Route -> Bool
isActive page route =
    case ( page, route ) of
        ( Dashboard, Route.Dashboard ) ->
            True

        ( Shop, Route.Shop _ ) ->
            True

        _ ->
            False


viewFooter : Shared -> Html msg
viewFooter _ =
    footer [ class "bg-white w-full flex flex-wrap mx-auto border-t border-grey-500 p-4 pt-6 h-40 bottom-0" ]
        [ p [ class "text-sm flex w-full justify-center items-center" ]
            [ text "Created with"
            , Icons.heart
            , text "by Satisfied Vagabonds"
            ]
        , img
            [ class "h-24 w-full"
            , src "/images/satisfied-vagabonds.svg"
            ]
            []
        ]



-- UPDATE


type External msg
    = UpdatedLoggedIn Model
    | RequiredAuthentication (Maybe msg)
    | ShowFeedback Feedback.Status String
    | HideFeedback
    | ShowContactModal


mapExternal : (msg -> msg2) -> External msg -> External msg2
mapExternal transform ext =
    case ext of
        UpdatedLoggedIn m ->
            UpdatedLoggedIn m

        RequiredAuthentication maybeM ->
            RequiredAuthentication (Maybe.map transform maybeM)

        ShowFeedback message status ->
            ShowFeedback message status

        HideFeedback ->
            HideFeedback

        ShowContactModal ->
            ShowContactModal


type alias UpdateResult =
    UR.UpdateResult Model Msg ExternalMsg


type ExternalMsg
    = AuthenticationSucceed
    | AuthenticationFailed


type Msg
    = NoOp
    | CompletedLoadTranslation String (Result Http.Error Translations)
    | ClickedTryAgainTranslation
    | CompletedLoadProfile (RemoteData (Graphql.Http.Error (Maybe Profile.Model)) (Maybe Profile.Model))
    | CompletedLoadSettings (RemoteData (Graphql.Http.Error (Maybe Community.Settings)) (Maybe Community.Settings))
    | ClickedTryAgainProfile Eos.Name
    | ClickedLogout
    | ShowNotificationModal Bool
    | ShowUserNav Bool
    | ShowMainNav Bool
    | ToggleLanguageItems
    | ClickedLanguage String
    | ClosedAuthModal
    | GotAuthMsg Auth.Msg
    | CompletedLoadUnread Value
    | KeyDown String
    | OpenCommunitySelector
    | CloseCommunitySelector
    | SelectCommunity Symbol (Cmd Msg)
    | GotFeedbackMsg Feedback.Msg
    | ClosedAddContactModal
    | GotContactMsg Contact.Msg
    | GotSearchMsg Search.Msg
    | GotActionMsg Action.Msg
    | SearchClosed
    | GotTime Posix


showContactModal : Model -> Model
showContactModal ({ shared } as model) =
    let
        addContactLimitDate =
            -- 01/01/2022
            1641006000000

        showContactModalFromDate =
            addContactLimitDate - Time.posixToMillis shared.now > 0
    in
    case profile model of
        Just profile_ ->
            { model
                | showContactModal =
                    showContactModalFromDate
                        && (Maybe.map (List.length >> (>) 1) profile_.contacts
                                |> Maybe.withDefault False
                           )
            }

        Nothing ->
            model


update : Msg -> Model -> UpdateResult
update msg model =
    let
        shared =
            model.shared

        { t, tr } =
            shared.translators

        focusMainContent b alternative =
            if b then
                Dom.focus "main-content"
                    |> Task.attempt (\_ -> NoOp)

            else
                Dom.focus alternative
                    |> Task.attempt (\_ -> NoOp)

        closeAllModals =
            { model
                | showNotificationModal = False
                , showUserNav = False
                , showMainNav = False
                , showAuthModal = False
            }
    in
    case msg of
        NoOp ->
            UR.init model

        GotTime date ->
            UR.init { model | date = Just date }

        GotActionMsg actionMsg ->
            handleActionMsg model actionMsg

        SearchClosed ->
            { model
                | searchModel =
                    Search.closeSearch shared model.authToken model.searchModel
                        |> Tuple.first
            }
                |> UR.init

        GotSearchMsg searchMsg ->
            let
                ( searchModel, searchCmd ) =
                    Search.update shared model.authToken model.searchModel searchMsg
            in
            { model | searchModel = searchModel }
                |> UR.init
                |> UR.addCmd (Cmd.map GotSearchMsg searchCmd)

        CompletedLoadTranslation lang (Ok transl) ->
            case model.profile of
                Loaded _ ->
                    UR.init { model | shared = Shared.loadTranslation (Ok ( lang, transl )) shared }
                        |> UR.addCmd (Ports.storeLanguage lang)

                _ ->
                    UR.init model

        CompletedLoadTranslation _ (Err err) ->
            UR.init { model | shared = Shared.loadTranslation (Err err) shared }
                |> UR.logHttpError msg err

        ClickedTryAgainTranslation ->
            UR.init { model | shared = Shared.toLoadingTranslation shared }
                |> UR.addCmd (fetchTranslations (Shared.language shared) shared)

        CompletedLoadProfile (RemoteData.Success profile_) ->
            let
                subscriptionDoc =
                    unreadCountSubscription model.accountName
                        |> Graphql.Document.serializeSubscription
            in
            case profile_ of
                Just p ->
                    { model | profile = Loaded p }
                        |> showContactModal
                        |> UR.init
                        |> UR.addPort
                            { responseAddress = CompletedLoadUnread (Encode.string "")
                            , responseData = Encode.null
                            , data =
                                Encode.object
                                    [ ( "name", Encode.string "subscribeToUnreadCount" )
                                    , ( "subscription", Encode.string subscriptionDoc )
                                    ]
                            }

                Nothing ->
                    UR.init model
                        |> UR.addCmd (Route.replaceUrl shared.navKey Route.Logout)

        CompletedLoadProfile (RemoteData.Failure err) ->
            UR.init
                { model
                    | profile =
                        case model.profile of
                            Loading accountName ->
                                LoadingFailed accountName err

                            _ ->
                                model.profile
                }
                |> UR.logGraphqlError msg err

        CompletedLoadProfile _ ->
            UR.init model

        CompletedLoadSettings (RemoteData.Success settings_) ->
            case settings_ of
                Just settings ->
                    { model
                        | hasShop = FeatureLoaded settings.hasShop
                        , hasObjectives = FeatureLoaded settings.hasObjectives
                        , hasKyc = FeatureLoaded settings.hasKyc
                    }
                        |> UR.init

                Nothing ->
                    UR.init model

        CompletedLoadSettings (RemoteData.Failure err) ->
            UR.init model
                |> UR.logGraphqlError msg err

        CompletedLoadSettings _ ->
            UR.init model

        ClickedTryAgainProfile accountName ->
            UR.init { model | profile = Loading accountName }
                |> UR.addCmd
                    (Api.Graphql.query shared
                        (Just model.authToken)
                        (Profile.query accountName)
                        CompletedLoadProfile
                    )

        ClickedLogout ->
            UR.init model
                |> UR.addCmd (Route.replaceUrl shared.navKey Route.Logout)
                |> UR.addPort
                    { responseAddress = ClickedLogout
                    , responseData = Encode.null
                    , data =
                        Encode.object
                            [ ( "name", Encode.string "logout" )
                            ]
                    }

        ShowNotificationModal b ->
            UR.init
                { closeAllModals
                    | showNotificationModal = b
                    , notification =
                        if b then
                            model.notification

                        else
                            Notification.readAll model.notification
                }
                |> UR.addCmd (focusMainContent (not b) "notifications-modal")

        ShowUserNav b ->
            UR.init { closeAllModals | showUserNav = b }
                |> UR.addCmd (focusMainContent (not b) "user-nav")

        ShowMainNav b ->
            UR.init { closeAllModals | showMainNav = b }
                |> UR.addCmd (focusMainContent (not b) "mobile-main-nav")

        ToggleLanguageItems ->
            UR.init { model | showLanguageItems = not model.showLanguageItems }

        ClickedLanguage lang ->
            UR.init
                { model
                    | shared = Shared.toLoadingTranslation shared
                    , showUserNav = False
                }
                |> UR.addCmd (fetchTranslations lang shared)

        ClosedAuthModal ->
            UR.init closeAllModals

        GotAuthMsg authMsg ->
            Auth.update authMsg shared model.auth
                |> UR.map
                    (\a -> { model | auth = a })
                    GotAuthMsg
                    (\extMsg uResult ->
                        case extMsg of
                            Auth.ClickedCancel ->
                                closeModal uResult
                                    |> UR.addExt AuthenticationFailed

                            Auth.CompletedAuth { user, token } auth ->
                                let
                                    cmd =
                                        case model.claimingAction.status of
                                            Action.ClaimInProgress action maybeProof ->
                                                -- If action claim is in progress,
                                                -- send a message to finish the claiming process
                                                -- when the user confirms the PIN.
                                                Task.succeed (GotActionMsg (Action.ActionClaimed action maybeProof))
                                                    |> Task.perform identity

                                            _ ->
                                                Cmd.none
                                in
                                closeModal uResult
                                    |> UR.mapModel
                                        (\m ->
                                            { m
                                                | profile = Loaded user
                                                , authToken = token
                                                , auth = auth
                                            }
                                        )
                                    |> UR.addExt AuthenticationSucceed
                                    |> UR.addCmd cmd

                            Auth.SetFeedback feedback ->
                                uResult
                                    |> UR.mapModel (\m -> { m | feedback = feedback })
                    )

        CompletedLoadUnread payload ->
            case Decode.decodeValue (unreadCountSubscription model.accountName |> Graphql.Document.decoder) payload of
                Ok res ->
                    { model | unreadCount = res }
                        |> UR.init

                Err _ ->
                    model
                        |> UR.init
                        |> UR.logImpossible msg []

        KeyDown key ->
            if key == "Esc" || key == "Escape" then
                UR.init { closeAllModals | showUserNav = False }

            else
                model
                    |> UR.init

        GotFeedbackMsg subMsg ->
            { model | feedback = Feedback.update subMsg model.feedback }
                |> UR.init

        OpenCommunitySelector ->
            { model | showCommunitySelector = True }
                |> UR.init

        CloseCommunitySelector ->
            { model | showCommunitySelector = False }
                |> UR.init

        SelectCommunity communityId doNext ->
            { model
                | selectedCommunity = communityId
                , showCommunitySelector = False
                , searchModel =
                    Search.closeSearch shared model.authToken model.searchModel
                        |> Tuple.first
                        |> (\searchModel -> { searchModel | selectedCommunity = communityId })
            }
                |> UR.init
                |> UR.addCmd (Api.Graphql.query shared (Just model.authToken) (Community.settingsQuery communityId) CompletedLoadSettings)
                |> UR.addPort
                    { responseAddress = msg
                    , responseData = Encode.null
                    , data =
                        Encode.object
                            [ ( "selectedCommunity", Eos.encodeSymbol communityId )
                            , ( "name", Encode.string "setSelectedCommunity" )
                            ]
                    }
                |> UR.addCmd doNext

        ClosedAddContactModal ->
            { model | showContactModal = False }
                |> UR.init

        GotContactMsg subMsg ->
            case profile model of
                Just userProfile ->
                    let
                        ( contactModel, cmd, contactResponse ) =
                            Contact.update subMsg
                                model.contactModel
                                shared
                                model.authToken

                        addContactResponse model_ =
                            case contactResponse of
                                Contact.NotAsked ->
                                    model_

                                Contact.WithError errorMessage ->
                                    { model_ | showContactModal = False }
                                        |> showFeedback Feedback.Failure errorMessage

                                Contact.WithContacts successMessage contacts ->
                                    { model_
                                        | profile = Loaded { userProfile | contacts = Just contacts }
                                        , showContactModal = False
                                    }
                                        |> showFeedback Feedback.Success successMessage
                    in
                    { model | contactModel = contactModel }
                        |> addContactResponse
                        |> UR.init
                        |> UR.addCmd (Cmd.map GotContactMsg cmd)

                Nothing ->
                    model |> UR.init


handleActionMsg : Model -> Action.Msg -> UpdateResult
handleActionMsg ({ shared } as model) actionMsg =
    let
        { t, tr } =
            shared.translators

        actionModelToLoggedIn : Action.Model -> Model
        actionModelToLoggedIn a =
            { model
                | claimingAction = a
                , feedback =
                    case ( a.feedback, actionMsg ) of
                        ( _, Action.Tick _ ) ->
                            -- Don't change feedback each second
                            model.feedback

                        ( Just (Action.Failure s), _ ) ->
                            Feedback.Shown Feedback.Failure s

                        ( Just (Action.Success s), _ ) ->
                            Feedback.Shown Feedback.Success s

                        ( Nothing, _ ) ->
                            model.feedback
            }
                |> (if a.needsPinConfirmation then
                        askedAuthentication

                    else
                        identity
                   )
    in
    Action.update (isAuth model) shared (Api.uploadImage shared) model.selectedCommunity model.accountName actionMsg model.claimingAction
        |> UR.map
            actionModelToLoggedIn
            GotActionMsg
            (\extMsg uR -> UR.addExt extMsg uR)
        |> UR.addCmd
            (case actionMsg of
                Action.AgreedToClaimWithProof _ ->
                    Task.perform identity (Task.succeed SearchClosed)

                _ ->
                    Cmd.none
            )


closeModal : UpdateResult -> UpdateResult
closeModal ({ model } as uResult) =
    { uResult
        | model =
            { model
                | showNotificationModal = False
                , showUserNav = False
                , showMainNav = False
                , showAuthModal = False
                , showContactModal = False
            }
    }


askedAuthentication : Model -> Model
askedAuthentication model =
    { model
        | showNotificationModal = False
        , showUserNav = False
        , showMainNav = False
        , showAuthModal = True
    }


showFeedback : Feedback.Status -> String -> Model -> Model
showFeedback feedbackStatus feedback model =
    { model | feedback = Feedback.Shown feedbackStatus feedback }



-- TRANSFORM


addNotification : Notification -> Model -> Model
addNotification notification model =
    { model
        | notification = Notification.addNotification notification model.notification
    }


readAllNotifications : Model -> Model
readAllNotifications model =
    { model | notification = Notification.readAll model.notification }


addCommunity : Model -> Community.Model -> Model
addCommunity model community =
    let
        communityInfo =
            { id = community.symbol
            , name = community.title
            , logo = community.logo
            , hasShop = community.hasShop
            , hasActions = community.hasObjectives
            , hasKyc = community.hasKyc
            }
    in
    { model
        | selectedCommunity = community.symbol
        , profile =
            case model.profile of
                Loaded profile_ ->
                    Loaded
                        { profile_
                            | communities =
                                communityInfo :: profile_.communities
                        }

                _ ->
                    model.profile
    }



-- INFO


profile : Model -> Maybe Profile.Model
profile model =
    case model.profile of
        Loaded profile_ ->
            Just profile_

        _ ->
            Nothing


isAccount : Eos.Name -> Model -> Bool
isAccount accountName model =
    Maybe.map .account (profile model) == Just accountName



-- UNREAD NOTIFICATIONS


type alias UnreadMeta =
    Int


unreadSelection : SelectionSet UnreadMeta Cambiatus.Object.UnreadNotifications
unreadSelection =
    Cambiatus.Object.UnreadNotifications.unreads


unreadCountSubscription : Eos.Name -> SelectionSet UnreadMeta RootSubscription
unreadCountSubscription name =
    let
        stringName =
            name
                |> Eos.nameToString

        args =
            { input = { account = stringName } }
    in
    Subscription.unreads args unreadSelection


jsAddressToMsg : List String -> Value -> Maybe Msg
jsAddressToMsg addr val =
    case addr of
        "GotAuthMsg" :: remainAddress ->
            Auth.jsAddressToMsg remainAddress val
                |> Maybe.map GotAuthMsg

        "CompletedLoadUnread" :: [] ->
            Decode.decodeValue (Decode.field "meta" Decode.value) val
                |> Result.map CompletedLoadUnread
                |> Result.toMaybe

        "GotActionMsg" :: remainAddress ->
            Action.jsAddressToMsg remainAddress val
                |> Maybe.map GotActionMsg

        _ ->
            Nothing


msgToString : Msg -> List String
msgToString msg =
    case msg of
        NoOp ->
            [ "Ignored" ]

        GotTime _ ->
            [ "GotTime" ]

        SearchClosed ->
            [ "SearchClosed" ]

        GotSearchMsg _ ->
            [ "GotSearchMsg" ]

        GotActionMsg actionMsg ->
            "GotActionMsg" :: Action.msgToString actionMsg

        CompletedLoadTranslation _ r ->
            [ "CompletedLoadTranslation", UR.resultToString r ]

        ClickedTryAgainTranslation ->
            [ "ClickedTryAgainTranslation" ]

        CompletedLoadProfile r ->
            [ "CompletedLoadProfile", UR.remoteDataToString r ]

        CompletedLoadSettings r ->
            [ "CompletedLoadSettings", UR.remoteDataToString r ]

        ClickedTryAgainProfile _ ->
            [ "ClickedTryAgainProfile" ]

        ClickedLogout ->
            [ "ClickedLogout" ]

        ShowNotificationModal _ ->
            [ "ShowNotificationModal" ]

        ShowUserNav _ ->
            [ "ShowUserNav" ]

        ShowMainNav _ ->
            [ "ShowMainNav" ]

        ToggleLanguageItems ->
            [ "ToggleLanguageItems" ]

        ClickedLanguage _ ->
            [ "ClickedLanguage" ]

        ClosedAuthModal ->
            [ "ClosedAuthModal" ]

        GotAuthMsg subMsg ->
            "GotAuthMsg" :: Auth.msgToString subMsg

        CompletedLoadUnread _ ->
            [ "CompletedLoadUnread" ]

        KeyDown _ ->
            [ "KeyDown" ]

        OpenCommunitySelector ->
            [ "OpenCommunitySelector" ]

        CloseCommunitySelector ->
            [ "CloseCommunitySelector" ]

        SelectCommunity _ _ ->
            [ "SelectCommunity" ]

        GotFeedbackMsg _ ->
            [ "GotFeedbackMsg" ]

        ClosedAddContactModal ->
            [ "ClosedAddContactModal" ]

        GotContactMsg _ ->
            [ "GotContactMsg" ]
