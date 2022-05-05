module Page.Shop.Editor exposing
    ( Model
    , Msg(..)
    , initCreate
    , initUpdate
    , msgToString
    , update
    , view
    )

import Api
import Cambiatus.Enum.Permission as Permission
import Community exposing (Balance)
import Eos
import Form
import Form.File
import Form.RichText
import Form.Select
import Form.Text
import Form.Toggle
import Form.Validate
import Graphql.Http
import Graphql.SelectionSet
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, classList, disabled, maxlength, type_)
import Html.Attributes.Aria exposing (ariaLabel)
import Html.Events exposing (onClick)
import Http
import Icons
import Log
import Markdown exposing (Markdown)
import Page
import RemoteData exposing (RemoteData)
import Result exposing (Result)
import Route
import Session.LoggedIn as LoggedIn exposing (External(..))
import Session.Shared exposing (Shared)
import Shop exposing (Product)
import Translation
import UpdateResult as UR
import View.Feedback as Feedback
import View.Modal as Modal



-- INIT


initCreate : LoggedIn.Model -> ( Model, Cmd Msg )
initCreate loggedIn =
    ( LoadingBalancesCreate
    , Api.getBalances loggedIn.shared loggedIn.accountName CompletedBalancesLoad
    )


initUpdate : Shop.Id -> LoggedIn.Model -> ( Model, Cmd Msg )
initUpdate productId loggedIn =
    ( LoadingBalancesUpdate productId
    , Api.getBalances loggedIn.shared loggedIn.accountName CompletedBalancesLoad
    )



-- MODEL


type alias Model =
    Status


type
    Status
    -- Create
    = LoadingBalancesCreate
    | EditingCreate (List Balance) FormData
    | Creating (List Balance) FormData
      -- Update
    | LoadingBalancesUpdate Shop.Id
    | LoadingSaleUpdate (List Balance)
    | EditingUpdate (List Balance) Product DeleteModalStatus FormData
    | Saving (List Balance) Product FormData
    | Deleting (List Balance) Product FormData
      -- Errors
    | LoadBalancesFailed Http.Error
    | LoadSaleFailed (Graphql.Http.Error (Maybe Product))


type alias FormData =
    { mainInformation : Form.Model MainInformationFormInput
    , images : Form.Model ImagesFormInput
    , priceAndInventory : Form.Model PriceAndInventoryFormInput
    , currentStep : Step
    }


type DeleteModalStatus
    = Open
    | Closed


type alias FormInput =
    { image : Form.File.Model
    , title : String
    , description : Form.RichText.Model
    , trackUnits : Bool
    , unitsInStock : String
    , price : String
    }


type alias FormOutput =
    { image : Maybe String
    , title : String
    , description : Markdown
    , unitTracking : Shop.StockTracking
    , price : Float
    }


type Step
    = MainInformation
    | Images MainInformationFormOutput
    | PriceAndInventory MainInformationFormOutput ImagesFormOutput


type alias FormInput2 =
    { currentStep : Step
    , mainInformation : MainInformationFormInput
    , images : ImagesFormInput
    , priceAndInventory : PriceAndInventoryFormInput
    }


type alias FormOutput2 =
    { name : String
    , description : Markdown
    , images : List String
    , price : Float
    , unitTracking : Shop.StockTracking
    }


createForm2 : Translation.Translators -> Eos.Symbol -> Form.Form msg FormInput2 FormOutput2
createForm2 translators symbol =
    Form.succeed
        (\mainInformation images priceAndInventory ->
            { name = mainInformation.name
            , description = mainInformation.description
            , images = images
            , price = priceAndInventory.price
            , unitTracking = priceAndInventory.unitTracking
            }
        )
        |> Form.withNesting
            { value = .mainInformation
            , update = \newMainInformation values -> { values | mainInformation = newMainInformation }
            }
            (mainInformationForm translators)
        |> Form.withNesting
            { value = .images
            , update = \newImages values -> { values | images = newImages }
            }
            imagesForm
        |> Form.withNesting
            { value = .priceAndInventory
            , update = \newPriceAndInventory values -> { values | priceAndInventory = newPriceAndInventory }
            }
            (priceAndInventoryForm translators symbol)


type alias MainInformationFormInput =
    { name : String
    , description : Form.RichText.Model
    }


type alias MainInformationFormOutput =
    { name : String, description : Markdown }


mainInformationForm : Translation.Translators -> Form.Form msg MainInformationFormInput MainInformationFormOutput
mainInformationForm translators =
    Form.succeed MainInformationFormOutput
        |> Form.with
            (Form.Text.init
                { -- TODO - I18N
                  label = "Name"
                , id = "product-name-input"
                }
                |> Form.textField
                    { parser =
                        Form.Validate.succeed
                            >> Form.Validate.stringShorterThan 255
                            >> Form.Validate.stringLongerThan 3
                            >> Form.Validate.validate translators
                    , value = .name
                    , update = \newName values -> { values | name = newName }
                    , externalError = always Nothing
                    }
            )
        |> Form.with
            (Form.RichText.init
                { -- TODO - I18N
                  label = "Description"
                }
                |> Form.richText
                    { parser = Ok
                    , value = .description
                    , update = \newDescription values -> { values | description = newDescription }
                    , externalError = always Nothing
                    }
            )


type alias ImagesFormInput =
    List Form.File.Model


type alias ImagesFormOutput =
    List String


imagesForm : Form.Form msg ImagesFormInput ImagesFormOutput
imagesForm =
    -- TODO - Use Form.list from community contacts PR
    Form.succeed []


type alias PriceAndInventoryFormInput =
    { price : String
    , unitsInStock : String
    , trackUnits : Bool
    }


type alias PriceAndInventoryFormOutput =
    { price : Float
    , unitTracking : Shop.StockTracking
    }


priceAndInventoryForm : Translation.Translators -> Eos.Symbol -> Form.Form msg PriceAndInventoryFormInput PriceAndInventoryFormOutput
priceAndInventoryForm translators symbol =
    Form.succeed PriceAndInventoryFormOutput
        |> Form.with
            (Form.Text.init
                { -- TODO - I18N
                  label = "Price"
                , id = "product-price-input"
                }
                |> Form.Text.withCurrency symbol
                |> Form.textField
                    { parser =
                        Form.Validate.succeed
                            >> Form.Validate.maskedFloat translators
                            >> Form.Validate.floatGreaterThan 0
                            >> Form.Validate.validate translators
                    , value = .price
                    , update = \newPrice values -> { values | price = newPrice }
                    , externalError = always Nothing
                    }
            )
        |> Form.with (stockTrackingForm translators)


stockTrackingForm : Translation.Translators -> Form.Form msg { input | unitsInStock : String, trackUnits : Bool } Shop.StockTracking
stockTrackingForm translators =
    Form.succeed
        (\availableUnits trackStock ->
            if trackStock then
                Shop.UnitTracking { availableUnits = availableUnits }

            else
                Shop.NoTracking
        )
        |> Form.with
            (Form.Text.init
                { -- TODO - I18N
                  label = "Quantity in stock"
                , id = "product-quantity-input"
                }
                |> Form.textField
                    { parser =
                        Form.Validate.succeed
                            >> Form.Validate.int
                            >> Form.Validate.intGreaterThanOrEqualTo 0
                            >> Form.Validate.validate translators
                    , value = .unitsInStock
                    , update = \newUnitsInStock values -> { values | unitsInStock = newUnitsInStock }
                    , externalError = always Nothing
                    }
            )
        |> Form.with
            (Form.Toggle.init
                { label = text ""
                , id = "product-track-units-toggle"
                }
                |> Form.toggle
                    { parser = Ok
                    , value = .trackUnits
                    , update = \newTrackUnits values -> { values | trackUnits = newTrackUnits }
                    , externalError = always Nothing
                    }
            )


createForm : LoggedIn.Model -> Form.Form Msg FormInput FormOutput
createForm loggedIn =
    let
        ({ t } as translators) =
            loggedIn.shared.translators
    in
    Form.succeed
        (\maybeImage title description price trackUnits unitsInStock ->
            { image = maybeImage
            , title = title
            , description = description
            , unitTracking =
                if trackUnits then
                    unitsInStock

                else
                    Shop.NoTracking
            , price = price
            }
        )
        |> Form.with
            (Form.introspect
                (\values ->
                    Form.File.init { label = t "shop.photo_label", id = "image-uploader" }
                        |> Form.File.withVariant (Form.File.LargeRectangle Form.File.Gray)
                        |> Form.File.withContainerAttrs
                            [ class "mb-10 lg:place-self-center lg:w-2/3"
                            , classList
                                [ ( "lg:row-span-5", not values.trackUnits )
                                , ( "lg:row-span-6", values.trackUnits )
                                ]
                            ]
                        |> Form.File.withAttrs [ class "border border-dashed border-gray-900 rounded" ]
                        |> Form.file
                            { translators = translators
                            , value = .image
                            , update = \image input -> { input | image = image }
                            , externalError = always Nothing
                            }
                        |> Form.optional
                )
            )
        |> Form.with
            (Form.Text.init { label = t "shop.what_label", id = "title-input" }
                |> Form.Text.withExtraAttrs [ maxlength 255 ]
                |> Form.Text.withContainerAttrs [ class "lg:w-2/3" ]
                |> Form.Text.withPlaceholder (t "shop.what_label")
                |> Form.textField
                    { parser =
                        Form.Validate.succeed
                            >> Form.Validate.stringShorterThan 255
                            >> Form.Validate.stringLongerThan 3
                            >> Form.Validate.validate translators
                    , value = .title
                    , update = \title input -> { input | title = title }
                    , externalError = always Nothing
                    }
            )
        |> Form.with
            (Form.RichText.init { label = t "shop.description_label" }
                |> Form.RichText.withContainerAttrs [ class "mb-10 lg:w-2/3" ]
                |> Form.RichText.withPlaceholder (t "shop.description_placeholder")
                |> Form.richText
                    { parser =
                        Form.Validate.succeed
                            >> Form.Validate.markdownLongerThan 10
                            >> Form.Validate.validate translators
                    , value = .description
                    , update = \description input -> { input | description = description }
                    , externalError = always Nothing
                    }
            )
        |> Form.with
            (Form.Text.init { label = t "shop.price_label", id = "price-input" }
                |> (case loggedIn.selectedCommunity of
                        RemoteData.Success community ->
                            Form.Text.withCurrency community.symbol

                        _ ->
                            identity
                   )
                |> Form.Text.withExtraAttrs [ Html.Attributes.min "0" ]
                |> Form.Text.withContainerAttrs [ class "lg:w-2/3" ]
                |> Form.textField
                    { parser =
                        Form.Validate.succeed
                            >> Form.Validate.maskedFloat translators
                            >> Form.Validate.floatGreaterThan 0
                            >> Form.Validate.validate translators
                    , value = .price
                    , update = \price input -> { input | price = price }
                    , externalError = always Nothing
                    }
            )
        |> Form.with
            (Form.Select.init
                { label = t "shop.track_stock_label"
                , id = "track-stock-select"
                , optionToString = boolToString
                }
                |> Form.Select.withOption False (t "shop.track_stock_no")
                |> Form.Select.withOption True (t "shop.track_stock_yes")
                |> Form.Select.withContainerAttrs [ class "mb-10 lg:w-2/3" ]
                |> Form.select (boolFromString >> Maybe.withDefault False)
                    { parser = Ok
                    , value = .trackUnits
                    , update = \trackUnits input -> { input | trackUnits = trackUnits }
                    , externalError = always Nothing
                    }
            )
        |> Form.with
            (Form.introspect
                (\values ->
                    if values.trackUnits then
                        Form.Text.init { label = t "shop.units_label", id = "units-in-stock-input" }
                            |> Form.Text.withPlaceholder "0"
                            |> Form.Text.asNumeric
                            |> Form.Text.withType Form.Text.Number
                            |> Form.Text.withExtraAttrs
                                [ Html.Attributes.min "0"
                                , class "text-center"
                                ]
                            |> Form.Text.withContainerAttrs [ class "lg:w-2/3" ]
                            |> Form.Text.withElements
                                [ button
                                    [ class "absolute top-1 bottom-1 left-1 px-4 rounded focus-ring bg-white text-orange-300 hover:text-orange-300/70"
                                    , type_ "button"
                                    , ariaLabel <| t "shop.subtract_unit"
                                    , onClick ClickedDecrementStockUnits
                                    ]
                                    [ Icons.minus "fill-current" ]
                                , button
                                    [ class "absolute top-1 bottom-1 right-1 px-4 rounded focus-ring bg-white text-orange-300 hover:text-orange-300/70"
                                    , type_ "button"
                                    , ariaLabel <| t "shop.add_unit"
                                    , onClick ClickedIncrementStockUnits
                                    ]
                                    [ Icons.plus "fill-current" ]
                                ]
                            |> Form.textField
                                { parser =
                                    Form.Validate.succeed
                                        >> Form.Validate.int
                                        >> Form.Validate.intGreaterThanOrEqualTo 0
                                        >> Form.Validate.map (\units -> Shop.UnitTracking { availableUnits = units })
                                        >> Form.Validate.validate translators
                                , value = .unitsInStock
                                , update = \unitsInStock input -> { input | unitsInStock = unitsInStock }
                                , externalError = always Nothing
                                }

                    else
                        Form.succeed Shop.NoTracking
                )
            )


boolToString : Bool -> String
boolToString bool =
    if bool then
        "True"

    else
        "False"


boolFromString : String -> Maybe Bool
boolFromString bool =
    case bool of
        "True" ->
            Just True

        "False" ->
            Just False

        _ ->
            Nothing


initFormData : FormData
initFormData =
    { mainInformation =
        Form.init
            { name = ""
            , description = Form.RichText.initModel "product-description-editor" Nothing
            }
    , images = Form.init []
    , priceAndInventory =
        Form.init
            { price = "0"
            , unitsInStock = "0"
            , trackUnits = False
            }
    , currentStep = MainInformation
    }


initEditingFormData : Product -> FormData
initEditingFormData product =
    { mainInformation =
        Form.init
            { name = product.title
            , description = Form.RichText.initModel "product-description-editor" (Just product.description)
            }

    -- TODO - Use images instead of image
    , images =
        product.image
            |> Form.File.initModel
            |> List.singleton
            |> Form.init
    , priceAndInventory =
        Form.init
            { price = String.fromFloat product.price
            , unitsInStock =
                case product.stockTracking of
                    Shop.NoTracking ->
                        String.fromInt 0

                    Shop.UnitTracking { availableUnits } ->
                        String.fromInt availableUnits
            , trackUnits = Shop.hasUnitTracking product
            }
    , currentStep = MainInformation
    }



-- VIEW


view : LoggedIn.Model -> Model -> { title : String, content : Html Msg }
view loggedIn model =
    let
        shared =
            loggedIn.shared

        t =
            shared.translators.t

        isEdit =
            case model of
                EditingUpdate _ _ _ _ ->
                    True

                Saving _ _ _ ->
                    True

                Deleting _ _ _ ->
                    True

                _ ->
                    False

        title =
            if isEdit then
                t "shop.edit_offer"

            else
                t "shop.create_offer"

        content =
            case model of
                LoadingBalancesCreate ->
                    Page.fullPageLoading shared

                LoadingBalancesUpdate _ ->
                    Page.fullPageLoading shared

                LoadingSaleUpdate _ ->
                    Page.fullPageLoading shared

                LoadBalancesFailed error ->
                    Page.fullPageError (t "shop.title") error

                LoadSaleFailed error ->
                    Page.fullPageGraphQLError (t "shop.title") error

                EditingCreate _ formData ->
                    viewForm loggedIn { isEdit = False, isDisabled = False } Closed formData

                Creating _ formData ->
                    viewForm loggedIn { isEdit = False, isDisabled = True } Closed formData

                EditingUpdate _ _ confirmDelete formData ->
                    viewForm loggedIn { isEdit = True, isDisabled = False } confirmDelete formData

                Saving _ _ formData ->
                    viewForm loggedIn { isEdit = True, isDisabled = True } Closed formData

                Deleting _ _ formData ->
                    viewForm loggedIn { isEdit = True, isDisabled = True } Closed formData
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
                Page.fullPageLoading shared

            RemoteData.NotAsked ->
                Page.fullPageLoading shared

            RemoteData.Failure e ->
                Page.fullPageGraphQLError (t "community.error_loading") e
    }


viewForm :
    LoggedIn.Model
    -> { isEdit : Bool, isDisabled : Bool }
    -> DeleteModalStatus
    -> FormData
    -> Html Msg
viewForm ({ shared } as loggedIn) { isEdit, isDisabled } deleteModal formData =
    let
        { t } =
            shared.translators

        ( actionText, pageTitle ) =
            if isEdit then
                ( t "menu.save", t "shop.edit_offer" )

            else
                ( t "menu.create", t "shop.create_offer" )

        viewForm_ formFn formModel submitText toFormMsg onSubmitMsg =
            Form.view [ class "container mx-auto p-4 z-10 lg:py-16 grid lg:grid-cols-2 lg:justify-items-center" ]
                shared.translators
                (\submitButton ->
                    -- TODO - "Delete product" button?
                    -- TODO - I18N, change message based on step
                    [ submitButton
                        [ class "button button-primary"
                        , disabled isDisabled
                        ]
                        [ text submitText ]
                    ]
                )
                formFn
                (Form.withDisabled isDisabled formModel)
                { toMsg = toFormMsg >> GotFormMsg
                , onSubmit = onSubmitMsg
                }
    in
    div [ class "flex flex-col flex-grow mb-10 lg:mb-0" ]
        [ Page.viewHeader loggedIn pageTitle
        , div [ class "flex items-center flex-grow relative bg-white lg:bg-transparent" ]
            [ div [ class "bg-white top-0 bottom-0 left-0 right-1/2 absolute hidden lg:block" ] []

            -- , Form.view [ class "container mx-auto p-4 z-10 lg:py-16 grid lg:grid-cols-2 lg:justify-items-center" ]
            --     shared.translators
            --     (\submitButton ->
            --         [ div [ class "lg:w-2/3 flex flex-col-reverse gap-4 lg:flex-row" ]
            --             [ if isEdit then
            --                 button
            --                     [ class "button button-danger w-full"
            --                     , disabled isDisabled
            --                     , onClick ClickedDelete
            --                     , type_ "button"
            --                     ]
            --                     [ text (t "shop.delete") ]
            --               else
            --                 text ""
            --             , submitButton
            --                 [ class "button button-primary w-full"
            --                 , disabled isDisabled
            --                 ]
            --                 [ text actionText ]
            --             ]
            --         , if isEdit && deleteModal == Open then
            --             viewConfirmDeleteModal t
            --           else
            --             text ""
            --         ]
            --     )
            --     (createForm loggedIn)
            --     (Form.withDisabled isDisabled form)
            --     { toMsg = GotFormMsg
            --     , onSubmit = ClickedSave
            --     }
            , case formData.currentStep of
                MainInformation ->
                    viewForm_ (mainInformationForm shared.translators)
                        formData.mainInformation
                        -- TODO - I18N
                        "Next"
                        MainInformationMsg
                        SubmittedMainInformation

                Images _ ->
                    viewForm_ imagesForm
                        formData.images
                        -- TODO - I18N
                        "Next"
                        ImagesMsg
                        SubmittedImages

                PriceAndInventory _ _ ->
                    case loggedIn.selectedCommunity of
                        RemoteData.Success community ->
                            viewForm_ (priceAndInventoryForm shared.translators community.symbol)
                                formData.priceAndInventory
                                actionText
                                PriceAndInventoryMsg
                                SubmittedPriceAndInventory

                        RemoteData.Failure err ->
                            Page.fullPageGraphQLError pageTitle err

                        _ ->
                            Page.fullPageLoading shared
            , if isEdit && deleteModal == Open then
                viewConfirmDeleteModal t

              else
                text ""
            ]
        ]


viewConfirmDeleteModal : (String -> String) -> Html Msg
viewConfirmDeleteModal t =
    Modal.initWith
        { closeMsg = ClickedDeleteCancel
        , isVisible = True
        }
        |> Modal.withHeader (t "shop.delete_modal.title")
        |> Modal.withBody
            [ text (t "shop.delete_modal.body") ]
        |> Modal.withFooter
            [ button
                [ class "modal-cancel"
                , onClick ClickedDeleteCancel
                , type_ "button"
                ]
                [ text (t "shop.delete_modal.cancel") ]
            , button
                [ class "modal-accept"
                , onClick ClickedDeleteConfirm
                , type_ "button"
                ]
                [ text (t "shop.delete_modal.confirm") ]
            ]
        |> Modal.toHtml



-- UPDATE


type alias UpdateResult =
    UR.UpdateResult Model Msg (External Msg)


type Msg
    = CompletedBalancesLoad (Result Http.Error (List Balance))
    | CompletedSaleLoad (RemoteData (Graphql.Http.Error (Maybe Product)) (Maybe Product))
    | GotFormMsg FormMsg
    | SubmittedMainInformation MainInformationFormOutput
    | SubmittedImages ImagesFormOutput
    | SubmittedPriceAndInventory PriceAndInventoryFormOutput
    | ClickedSave FormOutput
    | ClickedDelete
    | ClickedDeleteConfirm
    | ClickedDeleteCancel
    | GotSaveResponse (RemoteData (Graphql.Http.Error (Maybe Shop.Id)) (Maybe Shop.Id))
    | GotDeleteResponse (RemoteData (Graphql.Http.Error (Maybe ())) (Maybe ()))
    | ClosedAuthModal
    | ClickedDecrementStockUnits
    | ClickedIncrementStockUnits


type FormMsg
    = MainInformationMsg (Form.Msg MainInformationFormInput)
    | ImagesMsg (Form.Msg ImagesFormInput)
    | PriceAndInventoryMsg (Form.Msg PriceAndInventoryFormInput)


update : Msg -> Model -> LoggedIn.Model -> UpdateResult
update msg model loggedIn =
    let
        t =
            loggedIn.shared.translators.t
    in
    case msg of
        CompletedBalancesLoad (Ok balances) ->
            case model of
                LoadingBalancesCreate ->
                    initFormData
                        |> EditingCreate balances
                        |> UR.init

                LoadingBalancesUpdate saleId ->
                    let
                        addSaleFetch =
                            LoggedIn.query loggedIn
                                (Shop.productQuery saleId)
                                CompletedSaleLoad
                                |> UR.addExt
                    in
                    LoadingSaleUpdate balances
                        |> UR.init
                        |> addSaleFetch

                _ ->
                    model
                        |> UR.init
                        |> UR.logImpossible msg
                            "Completed loading balances, but user wasn't creating or updating sale"
                            (Just loggedIn.accountName)
                            { moduleName = "Page.Shop.Editor", function = "update" }
                            []

        CompletedBalancesLoad (Err error) ->
            LoadBalancesFailed error
                |> UR.init
                |> UR.logHttpError msg
                    (Just loggedIn.accountName)
                    "Got an error when loading balances for shop editor"
                    { moduleName = "Page.Shop.Editor", function = "update" }
                    [ Log.contextFromCommunity loggedIn.selectedCommunity ]
                    error

        CompletedSaleLoad (RemoteData.Success maybeSale) ->
            case ( model, maybeSale ) of
                ( LoadingSaleUpdate balances, Just sale ) ->
                    initEditingFormData sale
                        |> EditingUpdate balances sale Closed
                        |> UR.init

                ( _, _ ) ->
                    model
                        |> UR.init
                        |> UR.logImpossible msg
                            "Completed loading sale, but sale was unavailable or user wasn't editing sale"
                            (Just loggedIn.accountName)
                            { moduleName = "Page.Shop.Editor", function = "update" }
                            []

        CompletedSaleLoad (RemoteData.Failure error) ->
            LoadSaleFailed error
                |> UR.init
                |> UR.logGraphqlError msg
                    (Just loggedIn.accountName)
                    "Got an error when loading sale"
                    { moduleName = "Page.Shop.Editor", function = "update" }
                    []
                    error

        CompletedSaleLoad _ ->
            UR.init model

        ClickedSave formOutput ->
            case loggedIn.selectedCommunity of
                RemoteData.Success community ->
                    case model of
                        EditingCreate balances form ->
                            Creating balances form
                                |> UR.init
                                |> UR.addExt
                                    (LoggedIn.mutation
                                        loggedIn
                                        (Shop.createProduct
                                            { symbol = community.symbol
                                            , title = formOutput.title
                                            , description = formOutput.description
                                            , images =
                                                formOutput.image
                                                    |> Maybe.map List.singleton
                                                    |> Maybe.withDefault []
                                            , price = formOutput.price
                                            , stockTracking = formOutput.unitTracking
                                            }
                                            Shop.idSelectionSet
                                        )
                                        GotSaveResponse
                                    )
                                |> LoggedIn.withPrivateKey loggedIn
                                    [ Permission.Sell ]
                                    model
                                    { successMsg = msg, errorMsg = ClosedAuthModal }

                        EditingUpdate balances sale _ form ->
                            Saving balances sale form
                                |> UR.init
                                |> UR.addExt
                                    (LoggedIn.mutation
                                        loggedIn
                                        (Shop.updateProduct
                                            { id = sale.id
                                            , symbol = community.symbol
                                            , title = formOutput.title
                                            , description = formOutput.description
                                            , images =
                                                formOutput.image
                                                    |> Maybe.map List.singleton
                                                    |> Maybe.withDefault []
                                            , price = formOutput.price
                                            , stockTracking = formOutput.unitTracking
                                            }
                                            Shop.idSelectionSet
                                        )
                                        GotSaveResponse
                                    )
                                |> LoggedIn.withPrivateKey loggedIn
                                    [ Permission.Sell ]
                                    model
                                    { successMsg = msg, errorMsg = ClosedAuthModal }

                        _ ->
                            model
                                |> UR.init
                                |> UR.logImpossible msg
                                    "Clicked save shop item, but wasn't editing or creating shop offer"
                                    (Just loggedIn.accountName)
                                    { moduleName = "Page.Shop.Editor", function = "update" }
                                    []

                _ ->
                    UR.init model
                        |> UR.logImpossible msg
                            "Clicked save shop item, but community wasn't loaded"
                            (Just loggedIn.accountName)
                            { moduleName = "Page.Shop.Editor", function = "update" }
                            []

        ClickedDelete ->
            case model of
                EditingUpdate balances sale _ form ->
                    EditingUpdate balances sale Open form
                        |> UR.init

                _ ->
                    UR.init model

        ClickedDeleteCancel ->
            case model of
                EditingUpdate balances sale _ form ->
                    EditingUpdate balances sale Closed form
                        |> UR.init

                _ ->
                    UR.init model

        ClickedDeleteConfirm ->
            case model of
                EditingUpdate balances sale _ form ->
                    Deleting balances sale form
                        |> UR.init
                        |> UR.addExt
                            (LoggedIn.mutation loggedIn
                                (Shop.deleteProduct sale.id (Graphql.SelectionSet.succeed ()))
                                GotDeleteResponse
                            )
                        |> LoggedIn.withPrivateKey loggedIn
                            []
                            model
                            { successMsg = msg, errorMsg = ClosedAuthModal }

                _ ->
                    model
                        |> UR.init
                        |> UR.logImpossible msg
                            "Clicked delete shop item, but wasn't editing or creating shop offer"
                            (Just loggedIn.accountName)
                            { moduleName = "Page.Shop.Editor", function = "update" }
                            []

        GotSaveResponse (RemoteData.Success maybeId) ->
            let
                redirectUrl =
                    case maybeId of
                        Nothing ->
                            Route.Shop Shop.All

                        Just id ->
                            Route.ViewSale id
            in
            UR.init model
                |> UR.addCmd
                    (Route.replaceUrl loggedIn.shared.navKey redirectUrl)
                |> UR.addExt (ShowFeedback Feedback.Success (t "shop.create_offer_success"))

        GotSaveResponse (RemoteData.Failure error) ->
            let
                internalError =
                    loggedIn.shared.translators.t "error.unknown"
            in
            case model of
                Creating balances form ->
                    EditingCreate balances form
                        |> UR.init
                        |> UR.addExt (LoggedIn.ShowFeedback Feedback.Failure internalError)
                        |> UR.logGraphqlError msg
                            (Just loggedIn.accountName)
                            "Got an error when creating a shop offer"
                            { moduleName = "Page.Shop.Editor", function = "update" }
                            []
                            error

                Saving balances sale form ->
                    EditingUpdate balances sale Closed form
                        |> UR.init
                        |> UR.addExt (LoggedIn.ShowFeedback Feedback.Failure internalError)
                        |> UR.logGraphqlError msg
                            (Just loggedIn.accountName)
                            "Got an error when editing a shop offer"
                            { moduleName = "Page.Shop.Editor", function = "update" }
                            []
                            error

                _ ->
                    model
                        |> UR.init
                        |> UR.logImpossible msg
                            "Saved shop item, but wasn't creating or editing"
                            (Just loggedIn.accountName)
                            { moduleName = "Page.Shop.Editor", function = "update" }
                            []

        GotSaveResponse _ ->
            UR.init model

        GotDeleteResponse (RemoteData.Success _) ->
            model
                |> UR.init
                |> UR.addCmd
                    (Route.replaceUrl loggedIn.shared.navKey (Route.Shop Shop.All))
                |> UR.addExt (ShowFeedback Feedback.Success (t "shop.delete_offer_success"))

        GotDeleteResponse (RemoteData.Failure error) ->
            let
                internalError =
                    loggedIn.shared.translators.t "error.unknown"
            in
            case model of
                Deleting balances sale form ->
                    EditingUpdate balances sale Closed form
                        |> UR.init
                        |> UR.addExt (LoggedIn.ShowFeedback Feedback.Failure internalError)
                        |> UR.logGraphqlError msg
                            (Just loggedIn.accountName)
                            "Got an error when deleting a shop offer"
                            { moduleName = "Page.Shop.Editor", function = "update" }
                            []
                            error

                _ ->
                    model
                        |> UR.init
                        |> UR.logImpossible msg
                            "Deleted shop item, but wasn't in the state of Deleting"
                            (Just loggedIn.accountName)
                            { moduleName = "Page.Shop.Editor", function = "update" }
                            []

        GotDeleteResponse _ ->
            UR.init model

        ClosedAuthModal ->
            case model of
                EditingUpdate balances sale _ form ->
                    EditingUpdate balances sale Closed form
                        |> UR.init

                _ ->
                    UR.init model

        GotFormMsg subMsg ->
            updateForm loggedIn.shared subMsg model

        SubmittedMainInformation formOutput ->
            let
                maybeCurrentStep =
                    getFormData model
                        |> Maybe.map .currentStep
            in
            case maybeCurrentStep of
                Just MainInformation ->
                    model
                        |> setCurrentStep (Images formOutput)
                        |> UR.init

                _ ->
                    UR.init model
                        |> UR.logImpossible msg
                            "Submitted main information, but was in another step"
                            (Just loggedIn.accountName)
                            { moduleName = "Page.Shop.Editor", function = "update" }
                            []

        SubmittedImages formOutput ->
            let
                maybeCurrentStep =
                    getFormData model
                        |> Maybe.map .currentStep
            in
            case maybeCurrentStep of
                Just (Images mainInformation) ->
                    model
                        |> setCurrentStep (PriceAndInventory mainInformation formOutput)
                        |> UR.init

                _ ->
                    UR.init model
                        |> UR.logImpossible msg
                            "Submitted images, but was in another step"
                            (Just loggedIn.accountName)
                            { moduleName = "Page.Shop.Editor", function = "update" }
                            []

        SubmittedPriceAndInventory priceAndInventory ->
            let
                maybeCurrentStep =
                    getFormData model
                        |> Maybe.map .currentStep
            in
            case maybeCurrentStep of
                Just (PriceAndInventory mainInformation images) ->
                    -- TODO - Save/create the offer
                    UR.init model

                _ ->
                    UR.init model
                        |> UR.logImpossible msg
                            "Submitted price and inventory, but was in another step"
                            (Just loggedIn.accountName)
                            { moduleName = "Page.Shop.Editor", function = "update" }
                            []

        ClickedDecrementStockUnits ->
            updateFormStockUnits (\price -> price - 1) model

        ClickedIncrementStockUnits ->
            updateFormStockUnits (\price -> price + 1) model


updateFormStockUnits : (Int -> Int) -> Model -> UpdateResult
updateFormStockUnits updateFn model =
    let
        maybeFormInfo =
            case model of
                EditingCreate balances form ->
                    Just ( form, EditingCreate balances )

                Creating balances form ->
                    Just ( form, Creating balances )

                EditingUpdate balances product deleteModalStatus form ->
                    Just ( form, EditingUpdate balances product deleteModalStatus )

                Saving balances product form ->
                    Just ( form, Saving balances product )

                Deleting balances product form ->
                    Just ( form, Deleting balances product )

                _ ->
                    Nothing
    in
    case maybeFormInfo of
        Nothing ->
            UR.init model

        Just ( formData, updateModel ) ->
            Form.updateValues
                (\values ->
                    case String.toInt values.unitsInStock of
                        Just unitsInStock ->
                            { values
                                | unitsInStock =
                                    updateFn unitsInStock
                                        |> max 0
                                        |> String.fromInt
                            }

                        Nothing ->
                            values
                )
                formData.priceAndInventory
                |> (\priceAndInventory -> { formData | priceAndInventory = priceAndInventory })
                |> updateModel
                |> UR.init


getFormData : Model -> Maybe FormData
getFormData model =
    case model of
        EditingCreate _ formData ->
            Just formData

        Creating _ formData ->
            Just formData

        EditingUpdate _ _ _ formData ->
            Just formData

        Saving _ _ formData ->
            Just formData

        Deleting _ _ formData ->
            Just formData

        _ ->
            Nothing


setCurrentStep : Step -> Model -> Model
setCurrentStep newStep model =
    case model of
        EditingCreate balances formData ->
            EditingCreate balances { formData | currentStep = newStep }

        Creating balances formData ->
            Creating balances { formData | currentStep = newStep }

        EditingUpdate balances product deleteModalStatus formData ->
            EditingUpdate balances product deleteModalStatus { formData | currentStep = newStep }

        Saving balances product formData ->
            Saving balances product { formData | currentStep = newStep }

        Deleting balances product formData ->
            Deleting balances product { formData | currentStep = newStep }

        _ ->
            model


updateForm : Shared -> FormMsg -> Model -> UpdateResult
updateForm shared formMsg model =
    let
        maybeFormInfo =
            case model of
                EditingCreate balances form ->
                    Just ( form, EditingCreate balances )

                Creating balances form ->
                    Just ( form, Creating balances )

                EditingUpdate balances product deleteModalStatus form ->
                    Just ( form, EditingUpdate balances product deleteModalStatus )

                Saving balances product form ->
                    Just ( form, Saving balances product )

                Deleting balances product form ->
                    Just ( form, Deleting balances product )

                _ ->
                    Nothing
    in
    case maybeFormInfo of
        Nothing ->
            UR.init model

        Just ( formData, updateModel ) ->
            case formMsg of
                MainInformationMsg subMsg ->
                    Form.update shared subMsg formData.mainInformation
                        |> UR.fromChild
                            (\newMainInformation -> updateModel { formData | mainInformation = newMainInformation })
                            (GotFormMsg << MainInformationMsg)
                            LoggedIn.addFeedback
                            model

                ImagesMsg subMsg ->
                    Form.update shared subMsg formData.images
                        |> UR.fromChild (\newImages -> updateModel { formData | images = newImages })
                            (GotFormMsg << ImagesMsg)
                            LoggedIn.addFeedback
                            model

                PriceAndInventoryMsg subMsg ->
                    Form.update shared subMsg formData.priceAndInventory
                        |> UR.fromChild (\newPriceAndInventory -> updateModel { formData | priceAndInventory = newPriceAndInventory })
                            (GotFormMsg << PriceAndInventoryMsg)
                            LoggedIn.addFeedback
                            model


msgToString : Msg -> List String
msgToString msg =
    case msg of
        CompletedBalancesLoad r ->
            [ "CompletedBalancesLoad", UR.resultToString r ]

        CompletedSaleLoad r ->
            [ "CompletedSaleLoad", UR.remoteDataToString r ]

        ClickedSave _ ->
            [ "ClickedSave" ]

        ClickedDelete ->
            [ "ClickedDelete" ]

        ClickedDeleteConfirm ->
            [ "ClickedDeleteConfirm" ]

        ClickedDeleteCancel ->
            [ "ClickedDeleteCancel" ]

        GotSaveResponse r ->
            [ "GotSaveResponse", UR.remoteDataToString r ]

        GotDeleteResponse r ->
            [ "GotDeleteResponse", UR.remoteDataToString r ]

        ClosedAuthModal ->
            [ "ClosedAuthModal" ]

        GotFormMsg subMsg ->
            "GotFormMsg" :: formMsgToString subMsg

        SubmittedMainInformation _ ->
            [ "SubmittedMainInformation" ]

        SubmittedImages _ ->
            [ "SubmittedImages " ]

        SubmittedPriceAndInventory _ ->
            [ "SubmittedPriceAndInventory " ]

        ClickedDecrementStockUnits ->
            [ "ClickedDecrementStockUnits" ]

        ClickedIncrementStockUnits ->
            [ "ClickedIncrementStockUnits" ]


formMsgToString : FormMsg -> List String
formMsgToString msg =
    case msg of
        MainInformationMsg subMsg ->
            "MainInformationMsg" :: Form.msgToString subMsg

        ImagesMsg subMsg ->
            "ImagesMsg" :: Form.msgToString subMsg

        PriceAndInventoryMsg subMsg ->
            "PriceAndInventoryMsg" :: Form.msgToString subMsg
