module Session.LoggedIn exposing (External(..), ExternalMsg(..), Model, Msg(..), Page(..), ProfileStatus, addNotification, askedAuthentication, init, initLogin, isAccount, isActive, isAuth, jsAddressToMsg, mapExternal, maybePrivateKey, msgToString, profile, readAllNotifications, subscriptions, update, view)

import Account exposing (Profile, profileQuery)
import Api
import Api.Chat as Chat exposing (ChatPreferences)
import Api.Graphql
import Asset.Icon as Icon
import Auth
import Avatar
import Bespiral.Object
import Bespiral.Object.UnreadNotifications
import Bespiral.Query
import Bespiral.Subscription as Subscription
import Browser.Dom as Dom
import Community exposing (Balance)
import Eos
import Eos.Account as Eos
import Graphql.Document
import Graphql.Http
import Graphql.Operation exposing (RootQuery, RootSubscription)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, with)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onFocus, onInput, onSubmit, stopPropagationOn)
import Http
import I18Next exposing (Delims(..), Translations, t, tr)
import Icons
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode exposing (Value)
import Log
import Notification exposing (Notification)
import Ports
import Route exposing (Route)
import Session.Shared as Shared exposing (Shared)
import Shop
import Task exposing (Task)
import Time
import Translation
import UpdateResult as UR



-- INIT


init : Shared -> Eos.Name -> ( Model, Cmd Msg )
init shared accountName =
    let
        authModel =
            Auth.init shared
    in
    ( initModel shared authModel accountName
    , Cmd.batch
        [ Api.Graphql.query shared (profileQuery accountName) CompletedLoadProfile
        , Api.getBalances shared accountName CompletedLoadBalances
        ]
    )


fetchTranslations : String -> Shared -> Cmd Msg
fetchTranslations language shared =
    CompletedLoadTranslation language
        |> Translation.get language


initLogin : Shared -> Auth.Model -> Profile -> ( Model, Cmd Msg )
initLogin shared authModel profile_ =
    let
        model =
            initModel shared authModel profile_.accountName
    in
    ( { model
        | profile = Loaded profile_
      }
    , Cmd.none
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map GotAuthMsg (Auth.subscriptions model.auth)
        ]



-- MODEL


type alias Model =
    { shared : Shared
    , isAuthenticated : Bool
    , accountName : Eos.Name
    , profile : ProfileStatus
    , showUserNav : Bool
    , showLanguageItems : Bool
    , searchText : String
    , showNotificationModal : Bool
    , showMainNav : Bool
    , notification : Notification.Model
    , unreadCount : Int
    , showAuthModal : Bool
    , auth : Auth.Model
    , balances : List Balance
    }


initModel : Shared -> Auth.Model -> Eos.Name -> Model
initModel shared authModel accountName =
    { shared = shared
    , isAuthenticated = False
    , accountName = accountName
    , profile = Loading accountName
    , showUserNav = False
    , showLanguageItems = False
    , searchText = ""
    , showNotificationModal = False
    , showMainNav = False
    , notification = Notification.init
    , unreadCount = 0
    , showAuthModal = False
    , auth = authModel
    , balances = []
    }


type ProfileStatus
    = Loading Eos.Name
    | LoadingFailed Eos.Name (Graphql.Http.Error (Maybe Profile))
    | Loaded Profile


type Authentication
    = WithPrivateKey
    | WithScatter


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
    | News
    | Learn
    | Shop
    | FAQ
    | Profile


view : (Msg -> msg) -> Page -> Model -> Html msg -> Html msg
view thisMsg page ({ shared } as model) content =
    case ( Shared.translationStatus shared, model.profile ) of
        ( Shared.LoadingTranslation, _ ) ->
            Shared.viewFullLoading

        ( Shared.LoadingTranslationFailed err, _ ) ->
            Shared.viewFullError shared
                err
                ClickedTryAgainTranslation
                "An error ocurred while loading translation."
                |> Html.map thisMsg

        ( _, Loading _ ) ->
            Shared.viewFullLoading

        ( _, LoadingFailed accountName err ) ->
            Shared.viewFullGraphqlError shared
                err
                (ClickedTryAgainProfile accountName)
                "An error ocurred while loading profile."
                |> Html.map thisMsg

        ( _, Loaded profile_ ) ->
            viewHelper thisMsg page profile_ model content


viewHelper : (Msg -> msg) -> Page -> Profile -> Model -> Html msg -> Html msg
viewHelper thisMsg page profile_ ({ shared } as model) content =
    let
        ipfsUrl =
            shared.endpoints.ipfs

        onClickCloseAny =
            if model.showUserNav then
                onClick (ShowUserNav False)

            else if model.showNotificationModal then
                onClick (ShowNotificationModal False)

            else if model.showMainNav then
                onClick (ShowMainNav False)

            else if model.showAuthModal then
                onClick ClosedAuthModal

            else
                style "" ""
    in
    div
        [ class "min-h-screen flex flex-col" ]
        [ viewHeader model profile_ |> Html.map thisMsg
        , viewMainMenu page profile_ model |> Html.map thisMsg
        , div [ class "flex-grow" ] [ content ]
        , viewFooter shared
        , div [ onClickCloseAny ] [] |> Html.map thisMsg
        , viewUserNav page profile_ model
            |> Html.map thisMsg
        , viewNotification model
            |> Html.map thisMsg
        , if model.showAuthModal then
            div
                [ classList
                    [ ( "modal-old", True )
                    , ( "fade-in", True )
                    ]
                , onClickCloseAny
                ]
                [ div
                    [ class "card card--register card--modal"
                    , stopPropagationOn "click"
                        (Decode.succeed ( Ignored, True ))
                    ]
                    (Auth.view True shared model.auth
                        |> List.map (Html.map GotAuthMsg)
                    )
                ]
                |> Html.map thisMsg

          else
            text ""
        ]


viewHeader : Model -> Profile -> Html Msg
viewHeader ({ shared } as model) profile_ =
    let
        tr str values =
            I18Next.tr shared.translations I18Next.Curly str values
    in
    div [ class "w-full bg-white pr-4 pl-4 pt-6 pb-4 flex flex-wrap" ]
        [ a [ Route.href Route.Dashboard, class "h-12 w-2/3 lg:w-1/4 flex lg:items-center" ]
            [ img [ class "lg:hidden h-8", src shared.logoMobile ] []
            , img
                [ class "hidden lg:block lg:visible h-6"
                , src shared.logo
                ]
                []
            ]
        , div [ class "hidden lg:block lg:visible w-1/2" ] [ searchBar model ]
        , div [ class "w-1/3 h-10 flex z-20 lg:w-1/4" ]
            [ div [ class "relative mx-auto overflow-visible" ]
                [ a
                    [ class "outline-none"
                    , Route.href Route.Notification
                    ]
                    [ Icons.notification "mx-auto lg:mr-1 xl:mx-auto" ]
                , if model.unreadCount == 0 then
                    text ""

                  else
                    div [ class "absolute top-0 right-0 -mt-4 -mr-4 px-2 py-1 bg-orange-100 text-xs rounded-full" ]
                        [ text (String.fromInt model.unreadCount) ]
                ]
            , button
                [ class "w-1/2 xl:hidden"
                , onClick (ShowUserNav (not model.showUserNav))
                ]
                [ Avatar.view shared.endpoints.ipfs profile_.avatar "h-7 w-7 float-right" ]
            , button
                [ class "h-12 bg-gray-200 rounded-lg flex py-2 px-3 hidden xl:visible xl:flex"
                , onClick (ShowUserNav (not model.showUserNav))
                ]
                [ Avatar.view shared.endpoints.ipfs profile_.avatar "h-8 w-8"
                , div [ class "flex flex-wrap text-left pl-2" ]
                    [ p [ class "w-full font-sans uppercase text-gray-900 text-xs overflow-x-hidden" ]
                        [ text (tr "menu.welcome_message" [ ( "user_name", Eos.nameToString profile_.accountName ) ]) ]
                    , p [ class "w-full font-sans text-indigo-500 text-sm" ]
                        [ text (t shared.translations "menu.my_account") ]
                    ]
                , Icons.arrowDown "float-right"
                ]
            ]
        , div [ class "w-full mt-2 lg:hidden" ] [ searchBar model ]
        ]


searchBar : Model -> Html Msg
searchBar ({ shared } as model) =
    Html.form
        [ class "h-12 bg-gray-200 rounded-full flex items-center p-4"
        , onSubmit SubmitedSearch
        ]
        [ Icons.search ""
        , input
            [ class "bg-gray-200 w-full font-sans outline-none pl-3"
            , placeholder (t shared.translations "menu.search")
            , type_ "text"
            , value model.searchText
            , onFocus FocusedSearchInput
            , onInput EnteredSearch
            , required True
            ]
            []
        ]


viewMainMenu : Page -> Profile -> Model -> Html Msg
viewMainMenu page profile_ model =
    let
        ipfsUrl =
            model.shared.endpoints.ipfs

        menuItemClass =
            "mx-4 w-48 font-sans uppercase flex items-center justify-center leading-tight text-xs text-gray-600 hover:text-indigo-500"

        activeClass =
            "border-orange-100 border-b-2 text-indigo-500"

        iconClass =
            "w-6 h-6 fill-current hover:text-indigo-500 mr-5"
    in
    nav [ class "z-10 bg-white h-16 w-full flex overflow-x-auto" ]
        [ a
            [ classList
                [ ( menuItemClass, True )
                , ( activeClass, isActive page Route.Dashboard )
                ]
            , Route.href Route.Dashboard
            ]
            [ Icons.dashboard iconClass
            , text (t model.shared.translations "menu.dashboard")
            ]
        , a
            [ classList
                [ ( menuItemClass, True )
                , ( activeClass, isActive page Route.Communities )
                ]
            , Route.href Route.Communities
            ]
            [ Icons.communities iconClass
            , text (t model.shared.translations "menu.communities")
            ]
        , a
            [ classList
                [ ( menuItemClass, True )
                , ( activeClass, isActive page (Route.Shop (Just Shop.MyCommunities)) )
                ]
            , Route.href (Route.Shop (Just Shop.MyCommunities))
            ]
            [ Icons.shop iconClass
            , text (t model.shared.translations "menu.shop")
            ]
        ]


isActive : Page -> Route -> Bool
isActive page route =
    case ( page, route ) of
        ( Dashboard, Route.Dashboard ) ->
            True

        ( Communities, Route.Communities ) ->
            True

        ( Shop, Route.Shop _ ) ->
            True

        _ ->
            False


viewFooter : Shared -> Html msg
viewFooter shared =
    footer [ class "bg-white w-full flex flex-wrap mx-auto border-t border-grey p-4 pt-6 h-40 bottom-0" ]
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



-- VIEW >> USERNAV


viewUserNav : Page -> Profile -> Model -> Html Msg
viewUserNav page profile_ ({ shared } as model) =
    let
        text_ str =
            text (t shared.translations str)
    in
    nav
        [ id "user-nav"
        , classList
            [ ( "user-nav", True )
            , ( "user-nav--show", model.showUserNav )
            ]
        , tabindex -1
        ]
        [ div [ class "user-nav__user-info" ]
            [ span [ class "user-nav__user-info__name" ]
                [ text (Account.username profile_) ]
            , span [ class "user-nav__user-info__email" ]
                [ text (Maybe.withDefault "" profile_.email) ]
            ]
        , viewUserNavItem page
            Route.Profile
            [ Icon.accountCircle ""
            , text_ "menu.profile"
            ]
        , viewUserNavItem page
            Route.Notification
            [ Icon.bell ""
            , text_ "menu.notifications"
            ]
        , button
            [ class "user-nav__item"
            , onClick ToggleLanguageItems
            ]
            [ Icon.language ""
            , span [ class "user-nav__item-text" ] [ text "Language" ]
            , Icon.arrow
                (if model.showLanguageItems then
                    "user-nav__arrow user-nav__arrow--up"

                 else
                    "user-nav__arrow"
                )
            ]
        , if model.showLanguageItems then
            div [ class "user-nav__sub-itens" ]
                (Shared.viewLanguageItems shared ClickedLanguage)

          else
            text ""
        , div [ class "user-nav__separator" ]
            []
        , button
            [ classList [ ( "user-nav__item", True ) ]
            , onClick ClickedLogout
            ]
            [ Icon.logout ""
            , text_ "menu.logout"
            ]
        ]


viewUserNavItem : Page -> Route -> List (Html Msg) -> Html Msg
viewUserNavItem page route =
    a
        [ classList
            [ ( "user-nav__item", True )
            , ( "user-nav__item--active", isActive page route )
            ]
        , Route.href route
        , onClick (ShowUserNav False)
        ]



-- VIEW >> NOTIFICATION


viewNotification : Model -> Html msg
viewNotification model =
    let
        text_ str =
            text (t model.shared.translations str)

        hasUnread =
            not (List.isEmpty model.notification.unreadNotifications)

        viewUnread =
            if hasUnread then
                [ h2 [ class "notifications-modal__title" ]
                    [ text_ "menu.new_notifications" ]
                , ul [] (List.map (viewNotificationItem model.shared.translations) model.notification.unreadNotifications)
                ]

            else
                []

        hasRead =
            not (List.isEmpty model.notification.readNotifications)

        viewRead =
            if hasRead then
                [ h2 [ class "notifications-modal__title" ]
                    [ text_ "menu.previous_notifications" ]
                , ul [] (List.map (viewNotificationItem model.shared.translations) model.notification.readNotifications)
                ]

            else
                []
    in
    div
        [ id "notifications-modal"
        , classList
            [ ( "notifications-modal", True )

            -- , ( "notifications-modal--show", model.showNotificationModal )
            ]
        , tabindex -1
        ]
        (if hasRead || hasUnread then
            viewUnread
                ++ viewRead
                ++ [ button [ class "btn btn--primary btn--big" ]
                        [ text_ "menu.view_all" ]
                   ]

         else
            [ span [] [ text_ "menu.no_notification" ] ]
        )


viewNotificationItem : Translations -> Notification -> Html msg
viewNotificationItem translations notification =
    let
        text_ str username =
            text (I18Next.tr translations Curly str [ ( "username", username ) ])
    in
    case ( notification.class, notification.link ) of
        ( "chat-notification", Just link ) ->
            li
                []
                [ a
                    [ href link
                    , target "_blank"
                    ]
                    [ text_ notification.title notification.description ]
                ]

        ( _, _ ) ->
            li [] []



-- UPDATE


type External msg
    = UpdatedLoggedIn Model
    | RequiredAuthentication (Maybe msg)
    | UpdateBalances


mapExternal : (msg -> msg2) -> External msg -> External msg2
mapExternal transform ext =
    case ext of
        UpdatedLoggedIn m ->
            UpdatedLoggedIn m

        RequiredAuthentication maybeM ->
            RequiredAuthentication (Maybe.map transform maybeM)

        UpdateBalances ->
            UpdateBalances


type alias UpdateResult =
    UR.UpdateResult Model Msg ExternalMsg


type ExternalMsg
    = AuthenticationSucceed
    | AuthenticationFailed


type Msg
    = Ignored
    | CompletedLoadTranslation String (Result Http.Error Translations)
    | ClickedTryAgainTranslation
    | CompletedLoadProfile (Result (Graphql.Http.Error (Maybe Profile)) (Maybe Profile))
    | ClickedTryAgainProfile Eos.Name
    | ClickedLogout
    | EnteredSearch String
    | SubmitedSearch
    | ShowNotificationModal Bool
    | ShowUserNav Bool
    | ShowMainNav Bool
    | FocusedSearchInput
    | ToggleLanguageItems
    | ClickedLanguage String
    | CompletedChatTranslation (Result (Graphql.Http.Error (Maybe ChatPreferences)) (Maybe ChatPreferences))
    | ClosedAuthModal
    | GotAuthMsg Auth.Msg
    | ReceivedNotification String
    | CompletedLoadBalances (Result Http.Error (List Balance))
    | CompletedLoadUnread Value


update : Msg -> Model -> UpdateResult
update msg model =
    let
        shared =
            model.shared

        focusMainContent b alternative =
            if b then
                Dom.focus "main-content"
                    |> Task.attempt (\_ -> Ignored)

            else
                Dom.focus alternative
                    |> Task.attempt (\_ -> Ignored)

        closeAllModals =
            { model
                | showNotificationModal = False
                , showUserNav = False
                , showMainNav = False
                , showAuthModal = False
            }
    in
    case msg of
        Ignored ->
            UR.init model

        CompletedLoadTranslation lang (Ok transl) ->
            case model.profile of
                Loaded profile_ ->
                    UR.init { model | shared = Shared.loadTranslation (Ok ( lang, transl )) shared }
                        |> UR.addCmd (Chat.updateChatLanguage shared profile_ lang CompletedChatTranslation)
                        |> UR.addCmd (Ports.storeLanguage lang)

                _ ->
                    UR.init model

        CompletedLoadTranslation lang (Err err) ->
            UR.init { model | shared = Shared.loadTranslation (Err err) shared }
                |> UR.logHttpError msg err

        ClickedTryAgainTranslation ->
            UR.init { model | shared = Shared.toLoadingTranslation shared }
                |> UR.addCmd (fetchTranslations (Shared.language shared) shared)

        CompletedLoadProfile (Ok profile_) ->
            let
                subscriptionDoc =
                    unreadCountSubscription model.accountName
                        |> Graphql.Document.serializeSubscription
            in
            case profile_ of
                Just p ->
                    UR.init { model | profile = Loaded p }
                        |> UR.addCmd (Chat.updateChatLanguage shared p shared.language CompletedChatTranslation)
                        |> UR.addPort
                            { responseAddress = CompletedLoadProfile (Ok profile_)
                            , responseData = Encode.null
                            , data =
                                Encode.object
                                    [ ( "name", Encode.string "chatCredentials" )
                                    , ( "container", Encode.string "chat-manager" )
                                    , ( "credentials", Account.encodeProfileChat p )
                                    , ( "notificationAddress"
                                      , Encode.list Encode.string [ "GotPageMsg", "GotLoggedInMsg", "ReceivedNotification" ]
                                      )
                                    ]
                            }
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

        CompletedLoadProfile (Err err) ->
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

        ClickedTryAgainProfile accountName ->
            UR.init { model | profile = Loading accountName }
                |> UR.addCmd (Api.Graphql.query shared (profileQuery accountName) CompletedLoadProfile)

        ClickedLogout ->
            UR.init model
                |> UR.addCmd (Route.replaceUrl shared.navKey Route.Logout)
                |> UR.addPort
                    { responseAddress = ClickedLogout
                    , responseData = Encode.null
                    , data =
                        Encode.object
                            [ ( "name", Encode.string "logout" )
                            , ( "container", Encode.string "chat-manager" )
                            ]
                    }

        EnteredSearch s ->
            UR.init { model | searchText = s }

        SubmitedSearch ->
            UR.init model

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

        FocusedSearchInput ->
            UR.init model
                |> UR.addCmd (Route.pushUrl shared.navKey Route.Communities)

        ToggleLanguageItems ->
            UR.init { model | showLanguageItems = not model.showLanguageItems }

        ClickedLanguage lang ->
            UR.init
                { model
                    | shared = Shared.toLoadingTranslation shared
                    , showUserNav = False
                }
                |> UR.addCmd (fetchTranslations lang shared)

        CompletedChatTranslation _ ->
            UR.init model

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

                            Auth.CompletedAuth profile_ ->
                                closeModal uResult
                                    |> UR.mapModel
                                        (\m ->
                                            { m | isAuthenticated = True }
                                        )
                                    |> UR.addExt AuthenticationSucceed

                            Auth.UpdatedShared newShared ->
                                UR.mapModel
                                    (\m -> { m | shared = newShared })
                                    uResult
                    )

        ReceivedNotification from ->
            addNotification
                (chatNotification model from)
                model
                |> UR.init

        CompletedLoadBalances res ->
            case res of
                Ok bals ->
                    { model | balances = bals }
                        |> UR.init

                Err err ->
                    model
                        |> UR.init

        CompletedLoadUnread payload ->
            case Decode.decodeValue (unreadCountSubscription model.accountName |> Graphql.Document.decoder) payload of
                Ok res ->
                    { model | unreadCount = res.unreads }
                        |> UR.init

                Err e ->
                    model
                        |> UR.init
                        |> UR.logImpossible msg []


chatNotification : Model -> String -> Notification
chatNotification model from =
    { title = "menu.chat_message_notification"
    , description = from
    , class = "chat-notification"
    , unread = True
    , link = Just (model.shared.endpoints.chat ++ "/direct/" ++ from)
    }


closeModal : UpdateResult -> UpdateResult
closeModal ({ model } as uResult) =
    { uResult
        | model =
            { model
                | showNotificationModal = False
                , showUserNav = False
                , showMainNav = False
                , showAuthModal = False
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



-- TRANSFORM


addNotification : Notification -> Model -> Model
addNotification notification model =
    { model
        | notification = Notification.addNotification notification model.notification
    }


readAllNotifications : Model -> Model
readAllNotifications model =
    { model | notification = Notification.readAll model.notification }



-- INFO


profile : Model -> Maybe Profile
profile model =
    case model.profile of
        Loaded profile_ ->
            Just profile_

        _ ->
            Nothing


isAccount : Eos.Name -> Model -> Bool
isAccount accountName model =
    Maybe.map .accountName (profile model) == Just accountName



-- UNREAD NOTIFICATIONS


type alias UnreadMeta =
    { unreads : Int }


unreadSelection : SelectionSet UnreadMeta Bespiral.Object.UnreadNotifications
unreadSelection =
    SelectionSet.succeed UnreadMeta
        |> with Bespiral.Object.UnreadNotifications.unreads


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

        "ReceivedNotification" :: [] ->
            Decode.decodeValue
                (Decode.field "username" Decode.string)
                val
                |> Result.map ReceivedNotification
                |> Result.toMaybe

        "CompletedLoadUnread" :: [] ->
            Decode.decodeValue (Decode.field "meta" Decode.value) val
                |> Result.map CompletedLoadUnread
                |> Result.toMaybe

        _ ->
            Nothing


msgToString : Msg -> List String
msgToString msg =
    case msg of
        Ignored ->
            [ "Ignored" ]

        CompletedLoadTranslation _ r ->
            [ "CompletedLoadTranslation", UR.resultToString r ]

        ClickedTryAgainTranslation ->
            [ "ClickedTryAgainTranslation" ]

        CompletedLoadProfile r ->
            [ "CompletedLoadProfile", UR.resultToString r ]

        ClickedTryAgainProfile _ ->
            [ "ClickedTryAgainProfile" ]

        ClickedLogout ->
            [ "ClickedLogout" ]

        EnteredSearch _ ->
            [ "EnteredSearch" ]

        SubmitedSearch ->
            [ "SubmitedSearch" ]

        ShowNotificationModal _ ->
            [ "ShowNotificationModal" ]

        ShowUserNav _ ->
            [ "ShowUserNav" ]

        ShowMainNav _ ->
            [ "ShowMainNav" ]

        FocusedSearchInput ->
            [ "FocusedSearchInput" ]

        ToggleLanguageItems ->
            [ "ToggleLanguageItems" ]

        ClickedLanguage _ ->
            [ "ClickedLanguage" ]

        CompletedChatTranslation _ ->
            [ "CompletedChatTranslation" ]

        ClosedAuthModal ->
            [ "ClosedAuthModal" ]

        GotAuthMsg subMsg ->
            "GotAuthMsg" :: Auth.msgToString subMsg

        ReceivedNotification _ ->
            [ "ReceivedNotification" ]

        CompletedLoadBalances _ ->
            [ "CompletedLoadBalances" ]

        CompletedLoadUnread _ ->
            [ "CompletedLoadUnread" ]
