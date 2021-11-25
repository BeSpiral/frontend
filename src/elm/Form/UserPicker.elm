module Form.UserPicker exposing
    ( init, Options
    , withDisabled
    , getId, isEmpty
    , view, ViewConfig
    , Model, update, Msg, msgToString
    , MultiplePickerModel, initMultiple, fromMultiplePicker, toMultiplePicker, getMultipleProfiles
    , SinglePickerModel, initSingle, fromSinglePicker, toSinglePicker, getSingleProfile
    )

{-| Creates a Cambiatus-style UserPicker. Use it within a `Form.Form`:

    Form.UserPicker.init
        { label = "Pick validators"
        , currentUser = loggedIn.accountName
        }


# Initializing

@docs init, Options


# Helpers


## Adding attributes

@docs withDisabled


# Getters

@docs getId, isEmpty


# View

@docs view, ViewConfig


# The elm architecture

This is how you actually use this component!

@docs Model, initModel, update, Msg, msgToString


## Multiple users picker

@docs MultiplePickerModel, initMultiple, fromMultiplePicker, toMultiplePicker, getMultipleProfiles


## single user picker

@docs SinglePickerModel, initSingle, fromSinglePicker, toSinglePicker, getSingleProfile

-}

import Avatar
import Eos.Account
import Html exposing (Html, button, div, label, li, span, ul)
import Html.Attributes exposing (class, disabled)
import Html.Attributes.Aria exposing (ariaLabel)
import Html.Events exposing (onClick)
import Icons
import List.Extra
import Maybe.Extra
import Profile
import Profile.Summary
import Select
import Session.Shared as Shared
import Simple.Fuzzy
import View.Form



-- OPTIONS


type Options msg
    = Options
        { label : String
        , disabled : Bool
        , currentUser : Eos.Account.Name
        , profiles : List Profile.Minimal
        }


{-| Initializes a UserPicker
-}
init :
    { label : String
    , currentUser : Eos.Account.Name
    , profiles : List Profile.Minimal
    }
    -> Options msg
init { label, currentUser, profiles } =
    Options
        { label = label
        , disabled = False
        , currentUser = currentUser
        , profiles = profiles
        }



-- ADDING ATTRIBUTES


{-| Determines if the UserPicker should be disabled
-}
withDisabled : Bool -> Options msg -> Options msg
withDisabled disabled (Options options) =
    Options { options | disabled = disabled }



-- VIEW


type alias ViewConfig msg =
    { onBlur : String -> msg
    , value : Model
    , error : Html msg
    , hasError : Bool
    , translators : Shared.Translators
    }


settings : Options msg -> ViewConfig msg -> Select.Config Msg Profile.Minimal
settings (Options options) viewConfig =
    let
        { t } =
            viewConfig.translators

        minQueryLength =
            2

        toLabel : Profile.Minimal -> String
        toLabel p =
            Eos.Account.nameToString p.account
    in
    Select.newConfig
        { onSelect = SelectedUser
        , toLabel = toLabel
        , filter =
            \query items ->
                if String.length query < minQueryLength then
                    Nothing

                else
                    let
                        accountItems =
                            Simple.Fuzzy.filter toLabel query items

                        nameItems : List Profile.Minimal
                        nameItems =
                            Simple.Fuzzy.filter
                                (\profile -> Maybe.withDefault "" profile.name)
                                query
                                items
                    in
                    (accountItems ++ nameItems)
                        |> List.Extra.unique
                        |> Just
        , onFocusItem = NoOp
        }
        |> Select.withInputClass "w-full input"
        |> Select.withInputClassList [ ( "with-error", viewConfig.hasError ) ]
        |> Select.withNotFound (t "community.actions.form.verifier_not_found")
        |> Select.withNotFoundClass "text-red border-solid border-gray-100 border rounded bg-white px-8 max-w-max"
        |> Select.withDisabled options.disabled
        |> Select.withItemClass "bg-indigo-500 hover:bg-opacity-80 focus:bg-opacity-80 active:bg-opacity-90"
        |> Select.withPrompt (t "community.actions.form.verifier_placeholder")
        |> Select.withItemHtml viewUserItem
        |> Select.withMenuClass "flex flex-col w-full border-t-none border-solid border-gray-100 border rounded-sm z-30 bg-white max-h-80 overflow-auto"
        |> Select.withOnBlur BlurredPicker


viewUserItem : Profile.Minimal -> Html Never
viewUserItem { avatar, name, account } =
    div [ class "flex flex-row items-center z-30 pt-4 pb-2 px-4" ]
        [ Avatar.view avatar "h-10 w-10 mr-4"
        , div [ class "flex flex-col border-dotted border-b border-gray-500 pb-1 w-full text-white text-left" ]
            [ span [ class "font-bold" ]
                [ Html.text <| Maybe.withDefault "" name ]
            , span [ class "font-light" ]
                [ Html.text <| Eos.Account.nameToString account ]
            ]
        ]


view : Options msg -> ViewConfig msg -> (Msg -> msg) -> Html msg
view ((Options options) as wrappedOptions) viewConfig toMsg =
    let
        (Model model) =
            viewConfig.value

        selectedProfiles =
            case model.selectedProfile of
                Multiple profiles_ ->
                    profiles_

                Single Nothing ->
                    []

                Single (Just profile) ->
                    [ profile ]
    in
    div [ class "mb-10" ]
        [ View.Form.label [] model.id options.label
        , Select.view (settings wrappedOptions viewConfig)
            model.selectState
            (List.filter
                (\profile ->
                    List.map .profile selectedProfiles
                        |> List.member profile
                        |> not
                )
                options.profiles
            )
            (List.map .profile selectedProfiles)
            |> Html.map (toMsg << GotSelectMsg)
        , viewConfig.error
        , ul [ class "mt-4 flex flex-wrap gap-4" ]
            (List.map
                (viewSelectedProfile wrappedOptions viewConfig
                    >> Html.map toMsg
                )
                selectedProfiles
            )
        ]


viewSelectedProfile :
    Options msg
    -> ViewConfig msg
    -> ProfileWithSummary
    -> Html Msg
viewSelectedProfile (Options options) viewConfig { profile, summary } =
    let
        (Model model) =
            viewConfig.value
    in
    li
        [ class "flex flex-col items-center relative"
        ]
        [ summary
            |> Profile.Summary.withRelativeSelector ("#" ++ model.id ++ " ~ ul")
            |> Profile.Summary.view { translators = viewConfig.translators }
                options.currentUser
                profile
            |> Html.map (GotProfileSummaryMsg profile)
        , button
            [ class "hover:opacity-80 focus-ring focus:ring-red focus:ring-opacity-30 rounded-sm mt-2"
            , onClick (ClickedRemoveProfile profile)
            , ariaLabel <|
                viewConfig.translators.tr "community.actions.form.unselect_user"
                    [ ( "username"
                      , Maybe.withDefault
                            (Eos.Account.nameToString profile.account)
                            profile.name
                      )
                    ]
            ]
            [ Icons.trash "" ]
        ]



-- GETTERS


getId : Model -> String
getId (Model model) =
    model.id



-- THE ELM ARCHITECTURE
-- MODEL


type Model
    = Model
        { selectState : Select.State
        , id : String
        , selectedProfile : SelectedProfile
        }


type SinglePickerModel
    = SinglePickerModel
        { selectState : Select.State
        , id : String
        , selectedProfile : Maybe ProfileWithSummary
        }


type MultiplePickerModel
    = MultiplePickerModel
        { selectState : Select.State
        , id : String
        , selectedProfiles : List ProfileWithSummary
        }


type SelectedProfile
    = Single (Maybe ProfileWithSummary)
    | Multiple (List ProfileWithSummary)


type alias ProfileWithSummary =
    { profile : Profile.Minimal
    , summary : Profile.Summary.Model
    }


{-| Initialize a `Model` that will take can have multiple profiles selected at
once
-}
initMultiple : { id : String } -> MultiplePickerModel
initMultiple { id } =
    MultiplePickerModel
        { selectState = Select.newState id
        , id = id
        , selectedProfiles = []
        }


{-| Initialize a `Model` that will have at most 1 selected profile at a time.
Selecting a new profile will replace the previously selected one.
-}
initSingle : { id : String } -> SinglePickerModel
initSingle { id } =
    SinglePickerModel
        { selectState = Select.newState id
        , id = id
        , selectedProfile = Nothing
        }



-- UPDATE


type Msg
    = NoOp
    | GotSelectMsg (Select.Msg Profile.Minimal)
    | SelectedUser Profile.Minimal
    | GotProfileSummaryMsg Profile.Minimal Profile.Summary.Msg
    | ClickedRemoveProfile Profile.Minimal
    | BlurredPicker


update : Options msg -> ViewConfig msg -> Msg -> Model -> ( Model, Cmd Msg, Maybe msg )
update options viewConfig msg (Model model) =
    case msg of
        NoOp ->
            ( Model model, Cmd.none, Nothing )

        GotSelectMsg subMsg ->
            let
                ( newState, cmd ) =
                    Select.update (settings options viewConfig)
                        subMsg
                        model.selectState
            in
            ( Model { model | selectState = newState }
            , cmd
            , Nothing
            )

        SelectedUser profile ->
            ( Model
                { model
                    | selectedProfile =
                        case model.selectedProfile of
                            Single _ ->
                                { profile = profile
                                , summary = Profile.Summary.init False
                                }
                                    |> Just
                                    |> Single

                            Multiple profiles ->
                                Multiple
                                    ({ profile = profile
                                     , summary = Profile.Summary.init False
                                     }
                                        :: profiles
                                    )
                }
            , Cmd.none
            , Nothing
            )

        GotProfileSummaryMsg targetProfile subMsg ->
            ( Model
                { model
                    | selectedProfile =
                        case model.selectedProfile of
                            Single Nothing ->
                                Single Nothing

                            Single (Just profile) ->
                                { profile | summary = Profile.Summary.update subMsg profile.summary }
                                    |> Just
                                    |> Single

                            Multiple profiles ->
                                profiles
                                    |> List.Extra.updateIf
                                        (.profile >> (==) targetProfile)
                                        (\profile -> { profile | summary = Profile.Summary.update subMsg profile.summary })
                                    |> Multiple
                }
            , Cmd.none
            , Nothing
            )

        ClickedRemoveProfile profileToRemove ->
            ( Model
                { model
                    | selectedProfile =
                        case model.selectedProfile of
                            Single _ ->
                                Single Nothing

                            Multiple profiles ->
                                Multiple
                                    (List.filter
                                        (.profile >> (/=) profileToRemove)
                                        profiles
                                    )
                }
            , Cmd.none
            , Nothing
            )

        BlurredPicker ->
            ( Model model, Cmd.none, Just (viewConfig.onBlur model.id) )


msgToString : Msg -> List String
msgToString msg =
    case msg of
        NoOp ->
            [ "NoOp" ]

        GotSelectMsg _ ->
            [ "GotSelectMsg" ]

        SelectedUser _ ->
            [ "SelectedUser" ]

        GotProfileSummaryMsg _ subMsg ->
            "GotProfileSummaryMsg" :: Profile.Summary.msgToString subMsg

        ClickedRemoveProfile _ ->
            [ "ClickedRemoveProfile" ]

        BlurredPicker ->
            [ "BlurredPicker" ]



-- TRANSFORMING DIFFERENT MODELS


isEmpty : Model -> Bool
isEmpty (Model model) =
    case model.selectedProfile of
        Single maybeProfile ->
            Maybe.Extra.isNothing maybeProfile

        Multiple profiles ->
            List.isEmpty profiles


getSingleProfile : SinglePickerModel -> Maybe Profile.Minimal
getSingleProfile (SinglePickerModel model) =
    Maybe.map .profile model.selectedProfile


getMultipleProfiles : MultiplePickerModel -> List Profile.Minimal
getMultipleProfiles (MultiplePickerModel model) =
    List.map .profile model.selectedProfiles


fromSinglePicker : SinglePickerModel -> Model
fromSinglePicker (SinglePickerModel model) =
    Model
        { selectState = model.selectState
        , id = model.id
        , selectedProfile = Single model.selectedProfile
        }


toSinglePicker : Model -> SinglePickerModel
toSinglePicker (Model model) =
    case model.selectedProfile of
        Single maybeProfile ->
            SinglePickerModel
                { selectState = model.selectState
                , id = model.id
                , selectedProfile = maybeProfile
                }

        Multiple selectedProfiles ->
            SinglePickerModel
                { selectState = model.selectState
                , id = model.id
                , selectedProfile = List.head selectedProfiles
                }


fromMultiplePicker : MultiplePickerModel -> Model
fromMultiplePicker (MultiplePickerModel model) =
    Model
        { selectState = model.selectState
        , id = model.id
        , selectedProfile = Multiple model.selectedProfiles
        }


toMultiplePicker : Model -> MultiplePickerModel
toMultiplePicker (Model model) =
    case model.selectedProfile of
        Single maybeProfile ->
            MultiplePickerModel
                { selectState = model.selectState
                , id = model.id
                , selectedProfiles =
                    maybeProfile
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []
                }

        Multiple profiles ->
            MultiplePickerModel
                { selectState = model.selectState
                , id = model.id
                , selectedProfiles = profiles
                }
