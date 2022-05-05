module Page.Shop exposing
    ( Model
    , Msg
    , init
    , msgToString
    , receiveBroadcast
    , update
    , view
    )

import Api
import Community exposing (Balance)
import Eos
import Eos.Account
import Graphql.Http
import Html exposing (Html, a, br, div, h1, h2, img, li, p, span, text, ul)
import Html.Attributes exposing (alt, class, classList, src)
import Html.Attributes.Aria exposing (ariaLabel)
import Http
import I18Next exposing (t)
import Page exposing (Session(..))
import Profile.Summary
import RemoteData exposing (RemoteData)
import Route
import Session.LoggedIn as LoggedIn exposing (External(..))
import Session.Shared as Shared
import Shop exposing (Filter, Product)
import Translation
import UpdateResult as UR
import View.Components



-- INIT


init : LoggedIn.Model -> Filter -> ( Model, Cmd Msg )
init loggedIn filter =
    let
        model =
            initModel filter
    in
    ( model
    , Cmd.batch
        [ LoggedIn.maybeInitWith CompletedLoadCommunity .selectedCommunity loggedIn
        , Api.getBalances loggedIn.shared loggedIn.accountName CompletedLoadBalances
        ]
    )



-- MODEL


type alias Model =
    { cards : Status
    , balances : List Balance
    , filter : Filter
    }


initModel : Filter -> Model
initModel filter =
    { cards = Loading
    , balances = []
    , filter = filter
    }


type Status
    = Loading
    | Loaded Eos.Symbol (List Card)
    | LoadingFailed (Graphql.Http.Error (List Product))


type alias Card =
    { product : Product
    , form : SaleTransferForm
    , profileSummary : Profile.Summary.Model
    , isAvailable : Bool
    }


cardFromSale : Product -> Card
cardFromSale p =
    { product = p
    , form = initSaleFrom
    , profileSummary = Profile.Summary.init False
    , isAvailable = not (Shop.isOutOfStock p)
    }


type alias SaleTransferForm =
    { unit : String
    , unitValidation : Validation
    , memo : String
    , memoValidation : Validation
    }


initSaleFrom : SaleTransferForm
initSaleFrom =
    { unit = ""
    , unitValidation = Valid
    , memo = ""
    , memoValidation = Valid
    }


type Validation
    = Valid



-- VIEW


view : LoggedIn.Model -> Model -> { title : String, content : Html Msg }
view loggedIn model =
    let
        { t } =
            loggedIn.shared.translators

        selectedCommunityName =
            case loggedIn.selectedCommunity of
                RemoteData.Success community ->
                    community.name

                _ ->
                    ""

        title =
            selectedCommunityName
                ++ " "
                ++ t "shop.title"

        viewFrozenAccountCard =
            if not loggedIn.hasAcceptedCodeOfConduct then
                LoggedIn.viewFrozenAccountCard loggedIn.shared.translators
                    { onClick = ClickedAcceptCodeOfConduct
                    , isHorizontal = True
                    }
                    [ class "mx-auto shadow-lg mb-6" ]

            else
                text ""

        content =
            case model.cards of
                Loading ->
                    div [ class "container mx-auto px-4 mt-6 mb-10" ]
                        [ viewFrozenAccountCard
                        , viewHeader loggedIn.shared.translators
                        , viewShopFilter loggedIn model
                        , Page.fullPageLoading loggedIn.shared
                        ]

                LoadingFailed e ->
                    Page.fullPageGraphQLError (t "shop.title") e

                Loaded symbol cards ->
                    div [ class "container mx-auto px-4 mt-6" ]
                        (if List.isEmpty cards && model.filter == Shop.All then
                            [ viewFrozenAccountCard
                            , viewEmptyState loggedIn.shared.translators symbol model
                            ]

                         else if List.isEmpty cards && model.filter == Shop.UserSales then
                            [ viewFrozenAccountCard
                            , viewHeader loggedIn.shared.translators
                            , viewShopFilter loggedIn model
                            , viewEmptyState loggedIn.shared.translators symbol model
                            ]

                         else
                            [ viewFrozenAccountCard
                            , viewHeader loggedIn.shared.translators
                            , viewShopFilter loggedIn model
                            , viewGrid loggedIn cards
                            ]
                        )
    in
    { title = title
    , content =
        case RemoteData.map .hasShop loggedIn.selectedCommunity of
            RemoteData.Success True ->
                content

            RemoteData.Success False ->
                Page.fullPageNotFound
                    (t "error.pageNotFound")
                    (t "shop.disabled.description")

            RemoteData.Loading ->
                Page.fullPageLoading loggedIn.shared

            RemoteData.NotAsked ->
                Page.fullPageLoading loggedIn.shared

            RemoteData.Failure e ->
                Page.fullPageGraphQLError (t "community.error_loading") e
    }


viewHeader : Shared.Translators -> Html Msg
viewHeader { t } =
    h1
        [ class "font-bold text-lg"
        , ariaLabel <| t "shop.headline_no_emoji"
        ]
        [ text <| t "shop.headline"
        ]


viewShopFilter : LoggedIn.Model -> Model -> Html Msg
viewShopFilter loggedIn model =
    let
        { t } =
            loggedIn.shared.translators

        newFilter =
            case model.filter of
                Shop.All ->
                    Shop.UserSales

                Shop.UserSales ->
                    Shop.All
    in
    div [ class "grid xs-max:grid-cols-1 grid-cols-2 md:flex mt-4 gap-4" ]
        [ View.Components.disablableLink
            { isDisabled = not loggedIn.hasAcceptedCodeOfConduct }
            [ class "w-full md:w-40 button button-primary"
            , classList [ ( "button-disabled", not loggedIn.hasAcceptedCodeOfConduct ) ]

            -- TODO - Maybe we should check that the user has permission to sell
            , Route.href Route.NewSale
            ]
            [ text <| t "shop.create_new_offer" ]
        , a
            [ class "w-full md:w-40 button button-secondary"
            , Route.href (Route.Shop newFilter)
            ]
            [ case model.filter of
                Shop.UserSales ->
                    text <| t "shop.see_all"

                Shop.All ->
                    text <| t "shop.see_mine"
            ]
        ]



-- VIEW GRID


viewEmptyState : Translation.Translators -> Eos.Symbol -> Model -> Html Msg
viewEmptyState { t, tr } communitySymbol model =
    let
        title =
            case model.filter of
                Shop.UserSales ->
                    text <| t "shop.empty.user_title"

                Shop.All ->
                    text <| t "shop.empty.all_title"

        description =
            case model.filter of
                Shop.UserSales ->
                    [ text <| tr "shop.empty.you_can_offer" [ ( "symbol", Eos.symbolToSymbolCodeString communitySymbol ) ]
                    ]

                Shop.All ->
                    [ text <| t "shop.empty.no_one_is_selling"
                    , br [] []
                    , br [] []
                    , text <| t "shop.empty.offer_something"
                    ]
    in
    div [ class "flex flex-col items-center justify-center my-10" ]
        [ img
            [ src "/images/seller_confused.svg"
            , alt ""
            ]
            []
        , p [ class "font-bold text-black mt-4 text-center" ] [ title ]
        , p [ class "text-black text-center mt-4" ] description
        , a
            [ class "button button-primary mt-6 md:px-6 w-full md:w-max"
            , Route.href Route.NewSale
            ]
            [ text <| t "shop.empty.create_new" ]
        ]


viewGrid : LoggedIn.Model -> List Card -> Html Msg
viewGrid loggedIn cards =
    let
        outOfStockCards =
            cards
                |> List.filter (.isAvailable >> not)

        availableCards =
            cards
                |> List.filter .isAvailable
    in
    div [ class "mt-6 mb-10" ]
        [ ul [ class "grid gap-4 xs-max:grid-cols-1 grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5" ]
            (List.indexedMap
                (viewCard loggedIn)
                (availableCards ++ outOfStockCards)
            )
        ]


viewCard : LoggedIn.Model -> Int -> Card -> Html Msg
viewCard loggedIn index card =
    let
        ({ t, tr } as translators) =
            loggedIn.shared.translators

        image =
            -- TODO - We only show one image
            List.head card.product.images
                |> Maybe.withDefault
                    ("/icons/shop-placeholder"
                        ++ (index
                                |> modBy 3
                                |> String.fromInt
                           )
                        ++ ".svg"
                    )

        isFree =
            card.product.price == 0
    in
    li [ class "rounded bg-white" ]
        [ a
            [ class "h-full flex flex-col hover:shadow-md transition-shadow duration-300"
            , Html.Attributes.title card.product.title
            , Route.href (Route.ViewSale card.product.id)
            ]
            [ img [ src image, alt "", class "rounded-t h-32 object-cover" ] []
            , div [ class "p-4 flex flex-col flex-grow" ]
                [ h2 [ class "line-clamp-3 text-black" ] [ text card.product.title ]
                , p [ class "font-bold text-gray-900 text-sm uppercase mb-auto line-clamp-2 mt-1" ]
                    [ if loggedIn.accountName == card.product.creatorId then
                        text <| t "shop.by_you"

                      else
                        text <|
                            tr "shop.by_user"
                                [ ( "user"
                                  , card.product.creator.name
                                        |> Maybe.withDefault (Eos.Account.nameToString card.product.creator.account)
                                  )
                                ]
                    ]
                , div [ class "font-bold flex flex-col mt-4" ]
                    [ span
                        [ class "text-lg"
                        , classList
                            [ ( "text-green", card.isAvailable )
                            , ( "text-gray-900", not card.isAvailable )
                            , ( "lowercase", isFree )
                            ]
                        ]
                        [ if isFree then
                            text <| t "shop.free"

                          else
                            text <|
                                Eos.formatSymbolAmount translators
                                    card.product.symbol
                                    card.product.price
                        ]
                    , span
                        [ classList
                            [ ( "text-sm text-gray-333 uppercase", card.isAvailable )
                            , ( "text-red font-normal lowercase", not card.isAvailable )
                            ]
                        ]
                        [ if not card.isAvailable then
                            text <| t "shop.sold_out"

                          else if isFree then
                            text <| t "shop.enjoy"

                          else
                            text <| Eos.symbolToSymbolCodeString card.product.symbol
                        ]
                    ]
                ]
            ]
        ]



--- UPDATE


type alias UpdateResult =
    UR.UpdateResult Model Msg (External Msg)


type Msg
    = CompletedSalesLoad Eos.Symbol (RemoteData (Graphql.Http.Error (List Product)) (List Product))
    | CompletedLoadCommunity Community.Model
    | CompletedLoadBalances (Result Http.Error (List Balance))
    | ClickedAcceptCodeOfConduct


update : Msg -> Model -> LoggedIn.Model -> UpdateResult
update msg model loggedIn =
    case msg of
        CompletedSalesLoad symbol (RemoteData.Success sales) ->
            UR.init { model | cards = Loaded symbol (List.map cardFromSale sales) }

        CompletedSalesLoad _ (RemoteData.Failure err) ->
            UR.init { model | cards = LoadingFailed err }
                |> UR.logGraphqlError msg
                    (Just loggedIn.accountName)
                    "Got an error when loading sales from shop"
                    { moduleName = "Page.Shop", function = "update" }
                    []
                    err

        CompletedSalesLoad _ _ ->
            UR.init model

        CompletedLoadCommunity community ->
            UR.init model
                |> UR.addExt
                    (LoggedIn.query loggedIn
                        (Shop.productsQuery model.filter loggedIn.accountName community.symbol)
                        (CompletedSalesLoad community.symbol)
                    )

        CompletedLoadBalances res ->
            case res of
                Ok bals ->
                    { model | balances = bals }
                        |> UR.init

                Err _ ->
                    model
                        |> UR.init

        ClickedAcceptCodeOfConduct ->
            model
                |> UR.init
                |> UR.addExt LoggedIn.ShowCodeOfConductModal


receiveBroadcast : LoggedIn.BroadcastMsg -> Maybe Msg
receiveBroadcast broadcastMsg =
    case broadcastMsg of
        LoggedIn.CommunityLoaded community ->
            Just (CompletedLoadCommunity community)

        _ ->
            Nothing


msgToString : Msg -> List String
msgToString msg =
    case msg of
        CompletedSalesLoad _ r ->
            [ "CompletedSalesLoad", UR.remoteDataToString r ]

        CompletedLoadCommunity _ ->
            [ "CompletedLoadCommunity" ]

        CompletedLoadBalances _ ->
            [ "CompletedLoadBalances" ]

        ClickedAcceptCodeOfConduct ->
            [ "ClickedAcceptCodeOfConduct" ]
