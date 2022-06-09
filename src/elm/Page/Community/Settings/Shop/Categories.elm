module Page.Community.Settings.Shop.Categories exposing
    ( Model
    , Msg
    , init
    , msgToString
    , subscriptions
    , update
    , view
    )

import Community
import EverySet exposing (EverySet)
import Form
import Form.Text
import Form.Validate
import Graphql.Http
import Html exposing (Html, button, details, div, li, span, summary, text, ul)
import Html.Attributes exposing (class, classList)
import Html.Events exposing (onClick)
import Icons
import Json.Decode
import List.Extra
import Page
import RemoteData exposing (RemoteData)
import Session.LoggedIn as LoggedIn
import Shop.Category
import Slug exposing (Slug)
import Translation
import Tree
import UpdateResult as UR
import Utils
import View.Components
import View.Feedback
import View.Modal as Modal



-- MODEL


type alias Model =
    { expandedCategories : EverySet Shop.Category.Id
    , newCategoryState : NewCategoryState
    , categoryModalState : CategoryModalState
    }


init : LoggedIn.Model -> UpdateResult
init _ =
    -- TODO - Should we start them all expanded?
    { expandedCategories = EverySet.empty

    -- TODO - Should we allow multiple editors to be open at once?
    , newCategoryState = NotEditing
    , categoryModalState = Closed
    }
        |> UR.init
        |> UR.addExt (LoggedIn.RequestedReloadCommunityField Community.ShopCategoriesField)



-- TYPES


type NewCategoryState
    = NotEditing
    | EditingNewCategory
        { parent : Maybe Shop.Category.Id
        , form : Form.Model NewCategoryFormInput
        }


type CategoryModalState
    = Closed
    | Open Shop.Category.Id (Form.Model UpdateCategoryFormInput)


type Msg
    = NoOp
    | ClickedToggleExpandCategory Shop.Category.Id
    | ClickedAddCategory (Maybe Shop.Category.Id)
    | ClickedCancelAddCategory
    | ClickedCategory Shop.Category.Id
    | ClosedCategoryModal
    | GotAddCategoryFormMsg (Form.Msg NewCategoryFormInput)
    | SubmittedAddCategoryForm NewCategoryFormOutput
    | FinishedCreatingCategory (RemoteData (Graphql.Http.Error (Maybe Shop.Category.Model)) (Maybe Shop.Category.Model))
    | GotUpdateCategoryFormMsg (Form.Msg UpdateCategoryFormInput)
    | SubmittedUpdateCategoryForm UpdateCategoryFormOutput
    | FinishedUpdatingCategory (RemoteData (Graphql.Http.Error (Maybe Shop.Category.Model)) (Maybe Shop.Category.Model))


type alias UpdateResult =
    UR.UpdateResult Model Msg (LoggedIn.External Msg)



-- UPDATE


update : Msg -> Model -> LoggedIn.Model -> UpdateResult
update msg model loggedIn =
    let
        getCategory : Shop.Category.Id -> Maybe Shop.Category.Model
        getCategory categoryId =
            case Community.getField loggedIn.selectedCommunity .shopCategories of
                RemoteData.Success ( _, categories ) ->
                    findInTrees (\category -> category.id == categoryId) categories

                _ ->
                    Nothing
    in
    case msg of
        NoOp ->
            UR.init model

        ClickedToggleExpandCategory categoryId ->
            { model
                | expandedCategories =
                    if EverySet.member categoryId model.expandedCategories then
                        EverySet.remove categoryId model.expandedCategories

                    else
                        EverySet.insert categoryId model.expandedCategories
            }
                |> UR.init

        ClickedAddCategory maybeParentId ->
            { model
                | newCategoryState =
                    EditingNewCategory
                        { parent = maybeParentId
                        , form =
                            Form.init
                                { name = ""
                                , description = ""
                                }
                        }
            }
                |> UR.init

        ClickedCancelAddCategory ->
            { model | newCategoryState = NotEditing }
                |> UR.init

        ClickedCategory categoryId ->
            case getCategory categoryId of
                Just category ->
                    { model
                        | categoryModalState =
                            Open categoryId
                                (Form.init
                                    { name = category.name
                                    , description = category.description
                                    }
                                )
                    }
                        |> UR.init

                Nothing ->
                    UR.init model

        ClosedCategoryModal ->
            { model | categoryModalState = Closed }
                |> UR.init

        GotAddCategoryFormMsg subMsg ->
            case model.newCategoryState of
                NotEditing ->
                    UR.init model

                EditingNewCategory newCategoryData ->
                    Form.update loggedIn.shared subMsg newCategoryData.form
                        |> UR.fromChild
                            (\newForm ->
                                { model
                                    | newCategoryState =
                                        { newCategoryData | form = newForm }
                                            |> EditingNewCategory
                                }
                            )
                            GotAddCategoryFormMsg
                            LoggedIn.addFeedback
                            model

        SubmittedAddCategoryForm { name, slug, description } ->
            let
                parentId =
                    case model.newCategoryState of
                        NotEditing ->
                            Nothing

                        EditingNewCategory { parent } ->
                            parent
            in
            { model
                | newCategoryState =
                    case model.newCategoryState of
                        NotEditing ->
                            NotEditing

                        EditingNewCategory newCategoryData ->
                            { newCategoryData | form = Form.withDisabled True newCategoryData.form }
                                |> EditingNewCategory
            }
                |> UR.init
                |> UR.addExt
                    (LoggedIn.mutation loggedIn
                        (Shop.Category.create
                            { name = name
                            , description = description
                            , slug = slug
                            , parentId = parentId
                            }
                        )
                        FinishedCreatingCategory
                    )

        FinishedCreatingCategory (RemoteData.Success _) ->
            -- TODO - Should we open the form to create another category?
            { model | newCategoryState = NotEditing }
                |> UR.init
                -- TODO - Remove this once we update the UI automatically
                |> UR.addExt (LoggedIn.ShowFeedback View.Feedback.Success "Yay!")

        FinishedCreatingCategory (RemoteData.Failure _) ->
            -- TODO - re-enable form
            UR.init model
                -- TODO - I18N
                |> UR.addExt (LoggedIn.ShowFeedback View.Feedback.Failure "Aww :(")

        FinishedCreatingCategory _ ->
            UR.init model

        GotUpdateCategoryFormMsg subMsg ->
            case model.categoryModalState of
                Closed ->
                    UR.init model

                Open categoryId formModel ->
                    Form.update loggedIn.shared subMsg formModel
                        |> UR.fromChild
                            (\newFormModel -> { model | categoryModalState = Open categoryId newFormModel })
                            GotUpdateCategoryFormMsg
                            LoggedIn.addFeedback
                            model

        SubmittedUpdateCategoryForm formOutput ->
            case getCategory formOutput.id of
                Nothing ->
                    UR.init model

                Just category ->
                    { model
                        | categoryModalState =
                            case model.categoryModalState of
                                Closed ->
                                    Closed

                                Open categoryId formModel ->
                                    Open categoryId (Form.withDisabled True formModel)
                    }
                        |> UR.init
                        |> UR.addExt
                            (LoggedIn.mutation loggedIn
                                (Shop.Category.update category
                                    { name = formOutput.name
                                    , slug = formOutput.slug
                                    , description = formOutput.description
                                    }
                                )
                                FinishedUpdatingCategory
                            )

        FinishedUpdatingCategory (RemoteData.Success _) ->
            { model | categoryModalState = Closed }
                |> UR.init
                -- TODO - Remove this once we update the UI automatically
                |> UR.addExt (LoggedIn.ShowFeedback View.Feedback.Success "Yay!")

        FinishedUpdatingCategory (RemoteData.Failure _) ->
            -- TODO - re-enable form
            UR.init model
                -- TODO - I18N
                |> UR.addExt (LoggedIn.ShowFeedback View.Feedback.Failure "Aww :(")

        FinishedUpdatingCategory _ ->
            UR.init model



-- VIEW


view : LoggedIn.Model -> Model -> { title : String, content : Html Msg }
view loggedIn model =
    let
        title =
            -- TODO - I18N
            "TODO"
    in
    { title = title

    -- TODO - Add back arrow
    , content =
        case Community.getField loggedIn.selectedCommunity .shopCategories of
            RemoteData.NotAsked ->
                Page.fullPageLoading loggedIn.shared

            RemoteData.Loading ->
                Page.fullPageLoading loggedIn.shared

            RemoteData.Failure fieldErr ->
                case fieldErr of
                    Community.CommunityError err ->
                        Page.fullPageGraphQLError title err

                    Community.FieldError err ->
                        Page.fullPageGraphQLError title err

            RemoteData.Success ( _, categories ) ->
                view_ loggedIn.shared.translators model categories
    }


view_ : Translation.Translators -> Model -> List Shop.Category.Tree -> Html Msg
view_ translators model categories =
    div [ class "container mx-auto sm:px-4 sm:mt-6 sm:mb-20" ]
        [ div [ class "bg-white container mx-auto pt-6 pb-7 px-4 w-full sm:px-6 sm:rounded sm:shadow-lg lg:w-2/3" ]
            [ ul [ class "mb-2" ]
                (List.map
                    (\category ->
                        li []
                            [ viewCategoryTree translators model category
                            ]
                    )
                    categories
                )
            , viewAddCategory translators [ class "w-full pl-2" ] model Nothing
            ]
        , case model.categoryModalState of
            Closed ->
                text ""

            Open categoryId formModel ->
                case findInTrees (\category -> category.id == categoryId) categories of
                    Nothing ->
                        text ""

                    Just openCategory ->
                        viewCategoryModal translators openCategory formModel
        ]


viewCategoryTree : Translation.Translators -> Model -> Shop.Category.Tree -> Html Msg
viewCategoryTree translators model =
    Tree.restructure identity (viewCategoryWithChildren translators model)


viewCategory : Shop.Category.Model -> Html Msg
viewCategory category =
    button
        [ class "hover:underline"
        , Utils.onClickNoBubble (ClickedCategory category.id)
        ]
        [ text category.name
        ]


viewCategoryWithChildren : Translation.Translators -> Model -> Shop.Category.Model -> List (Html Msg) -> Html Msg
viewCategoryWithChildren translators model category children =
    let
        isOpen =
            EverySet.member category.id model.expandedCategories

        openArrowClass =
            if isOpen then
                ""

            else
                "-rotate-90"
    in
    li []
        [ details
            [ if isOpen then
                Html.Attributes.attribute "open" "true"

              else
                class ""
            , class "parent"
            ]
            [ summary
                [ class "marker-hidden flex items-center rounded-sm parent-hover:bg-blue-600/20"
                , Html.Events.preventDefaultOn "click"
                    (Json.Decode.succeed ( NoOp, True ))
                ]
                [ button
                    [ onClick (ClickedToggleExpandCategory category.id)
                    , class "flex items-center w-full"
                    ]
                    [ Icons.arrowDown (String.join " " [ "transition-transform", openArrowClass ])
                    , viewCategory category
                    ]
                ]
            , div [ class "ml-4 flex flex-col mb-4 mt-2" ]
                [ ul
                    [ class "grid gap-y-2"
                    , classList [ ( "mb-2", not (List.isEmpty children) ) ]
                    ]
                    children
                , viewAddCategory translators [] model (Just category)
                ]
            ]
        ]


viewAddCategory : Translation.Translators -> List (Html.Attribute Msg) -> Model -> Maybe Shop.Category.Model -> Html Msg
viewAddCategory translators attrs model maybeParentCategory =
    let
        parentId =
            Maybe.map .id maybeParentCategory

        viewAddCategoryButton customAttrs =
            button
                (class "flex items-center px-2 h-8 font-bold hover:bg-blue-600/20 rounded-sm"
                    :: onClick (ClickedAddCategory parentId)
                    :: customAttrs
                )
                [ Icons.plus "w-4 h-4 mr-2"
                , case maybeParentCategory of
                    Nothing ->
                        -- TODO - I18N
                        text "Add new category"

                    Just { name } ->
                        -- TODO - I18N
                        text ("Add sub-category of " ++ name)
                ]
    in
    case model.newCategoryState of
        NotEditing ->
            viewAddCategoryButton attrs

        EditingNewCategory newCategoryData ->
            if newCategoryData.parent == parentId then
                Form.view (class "bg-white border border-gray-300 rounded-md p-4" :: attrs)
                    translators
                    (\submitButton ->
                        [ div [ class "flex flex-col sm:flex-row justify-end gap-4" ]
                            [ button
                                [ class "button button-secondary w-full sm:w-40"
                                , onClick ClickedCancelAddCategory
                                ]
                                -- TODO - I18N
                                [ text "Cancel" ]
                            , submitButton [ class "button button-primary w-full sm:w-40" ]
                                -- TODO - I18N
                                [ text "Create" ]
                            ]
                        ]
                    )
                    (newCategoryForm translators)
                    newCategoryData.form
                    { toMsg = GotAddCategoryFormMsg
                    , onSubmit = SubmittedAddCategoryForm
                    }

            else
                viewAddCategoryButton attrs


viewCategoryModal : Translation.Translators -> Shop.Category.Model -> Form.Model UpdateCategoryFormInput -> Html Msg
viewCategoryModal translators category formModel =
    Modal.initWith
        { isVisible = True
        , closeMsg = ClosedCategoryModal
        }
        -- TODO - I18N
        |> Modal.withHeader "Editing category"
        |> Modal.withBody
            [ Form.viewWithoutSubmit [ class "mt-2" ]
                translators
                (\_ -> [])
                (updateCategoryForm translators category.id)
                formModel
                { toMsg = GotUpdateCategoryFormMsg
                }
            ]
        |> Modal.withFooter
            [ div [ class "flex flex-col w-full sm:flex-row gap-4 items-center justify-center" ]
                [ button
                    [ class "button button-secondary w-full sm:w-40"
                    , onClick ClosedCategoryModal
                    ]
                    -- TODO - I18N
                    [ text "Cancel" ]
                , button
                    [ class "button button-primary w-full sm:w-40"
                    , onClick
                        (Form.parse (updateCategoryForm translators category.id)
                            formModel
                            { onError = GotUpdateCategoryFormMsg
                            , onSuccess = SubmittedUpdateCategoryForm
                            }
                        )
                    ]
                    -- TODO - I18N
                    [ text "Save" ]
                ]
            ]
        |> Modal.withSize Modal.Large
        |> Modal.toHtml



-- FORM


type alias NewCategoryFormInput =
    { name : String
    , description : String
    }


type alias NewCategoryFormOutput =
    { name : String
    , slug : Slug
    , description : String
    }


newCategoryForm : Translation.Translators -> Form.Form msg NewCategoryFormInput NewCategoryFormOutput
newCategoryForm translators =
    Form.succeed
        (\{ name, slug } description ->
            { name = name, slug = slug, description = description }
        )
        |> Form.with (nameAndSlugForm translators { nameFieldId = "new-category-name" })
        |> Form.with
            (Form.Text.init
                -- TODO - I18N
                { label = "Description"
                , id = "new-category-description"
                }
                |> Form.textField
                    { parser =
                        Form.Validate.succeed
                            >> Form.Validate.stringLongerThan 3
                            >> Form.Validate.validate translators
                    , value = .description
                    , update = \newDescription values -> { values | description = newDescription }
                    , externalError = always Nothing
                    }
            )


type alias UpdateCategoryFormInput =
    { name : String
    , description : String
    }


type alias UpdateCategoryFormOutput =
    { id : Shop.Category.Id
    , name : String
    , slug : Slug
    , description : String
    }


updateCategoryForm : Translation.Translators -> Shop.Category.Id -> Form.Form msg UpdateCategoryFormInput UpdateCategoryFormOutput
updateCategoryForm translators id =
    Form.succeed
        (\{ name, slug } description ->
            { name = name
            , slug = slug
            , description = description
            , id = id
            }
        )
        |> Form.with (nameAndSlugForm translators { nameFieldId = "update-category-name" })
        |> Form.with
            (Form.Text.init
                -- TODO - I18N
                { label = "Description"
                , id = "update-category-description"
                }
                |> Form.Text.withContainerAttrs [ class "mb-0" ]
                |> Form.textField
                    { parser =
                        Form.Validate.succeed
                            >> Form.Validate.stringLongerThan 3
                            >> Form.Validate.validate translators
                    , value = .description
                    , update = \newDescription values -> { values | description = newDescription }
                    , externalError = always Nothing
                    }
            )


nameAndSlugForm : Translation.Translators -> { nameFieldId : String } -> Form.Form msg { values | name : String } { name : String, slug : Slug }
nameAndSlugForm translators { nameFieldId } =
    Form.succeed (\name slug -> { name = name, slug = slug })
        |> Form.with
            (Form.Text.init
                -- TODO - I18N
                { label = "Name"
                , id = nameFieldId
                }
                |> Form.Text.withContainerAttrs [ class "mb-4" ]
                |> Form.textField
                    { parser =
                        Form.Validate.succeed
                            >> Form.Validate.stringLongerThan 2
                            >> Form.Validate.custom
                                (\name ->
                                    case Slug.generate name of
                                        Nothing ->
                                            -- Errors are shown below, on the slug field
                                            Err (\_ -> "")

                                        Just slug ->
                                            if String.length (Slug.toString slug) < 2 then
                                                -- Errors are shown below, on the slug field
                                                Err (\_ -> "")

                                            else
                                                Ok name
                                )
                            >> Form.Validate.validate translators
                    , value = .name
                    , update = \newName values -> { values | name = newName }
                    , externalError = always Nothing
                    }
            )
        |> Form.with
            ((\{ name } ->
                case Slug.generate name of
                    Nothing ->
                        Form.arbitrary
                            (div [ class "mb-10" ]
                                [ View.Components.label []
                                    -- TODO - I18N
                                    { targetId = nameFieldId, labelText = "Slug" }
                                , if String.isEmpty name then
                                    span [ class "text-gray-400 italic" ]
                                        -- TODO - I18N
                                        [ text "Insert a name to generate the slug" ]

                                  else
                                    span [ class "form-error" ]
                                        -- TODO - I18N
                                        [ text "Invalid slug" ]
                                ]
                            )

                    Just slug ->
                        Form.arbitraryWith slug
                            (div [ class "mb-10" ]
                                [ View.Components.label []
                                    -- TODO - I18N
                                    { targetId = nameFieldId, labelText = "Slug" }
                                , text (Slug.toString slug)
                                ]
                            )
             )
                |> Form.introspect
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.newCategoryState of
        NotEditing ->
            Sub.none

        EditingNewCategory _ ->
            Utils.escSubscription ClickedCancelAddCategory



-- UTILS


findInTrees : (a -> Bool) -> List (Tree.Tree a) -> Maybe a
findInTrees fn trees =
    trees
        |> List.concatMap Tree.flatten
        |> List.Extra.find fn


msgToString : Msg -> List String
msgToString msg =
    case msg of
        NoOp ->
            [ "NoOp" ]

        ClickedToggleExpandCategory _ ->
            [ "ClickedToggleExpandCategory" ]

        ClickedAddCategory _ ->
            [ "ClickedAddCategory" ]

        ClickedCancelAddCategory ->
            [ "ClickedCancelAddCategory" ]

        ClickedCategory _ ->
            [ "ClickedCategory" ]

        ClosedCategoryModal ->
            [ "ClosedCategoryModal" ]

        GotAddCategoryFormMsg subMsg ->
            "GotAddCategoryFormMsg" :: Form.msgToString subMsg

        GotUpdateCategoryFormMsg subMsg ->
            "GotUpdateCategoryFormMsg" :: Form.msgToString subMsg

        SubmittedAddCategoryForm _ ->
            [ "SubmittedAddCategoryForm" ]

        FinishedCreatingCategory r ->
            [ "FinishedCreatingCategory", UR.remoteDataToString r ]

        SubmittedUpdateCategoryForm _ ->
            [ "SubmittedUpdateCategoryForm" ]

        FinishedUpdatingCategory r ->
            [ "FinishedUpdatingCategory", UR.remoteDataToString r ]
