module Page.Community.Settings.Info exposing
    ( Model
    , Msg
    , init
    , msgToString
    , receiveBroadcast
    , update
    , view
    )

import Api
import Community
import File exposing (File)
import Html exposing (Html, button, div, form, img, input, label, li, span, text, ul)
import Html.Attributes exposing (accept, class, for, id, maxlength, multiple, src, type_)
import Html.Events exposing (onSubmit)
import Http
import Icons
import Page
import RemoteData
import Route
import Session.LoggedIn as LoggedIn
import Session.Shared exposing (Shared)
import UpdateResult as UR
import View.Form.Input



-- MODEL


type alias Model =
    { logoUrl : Maybe String
    , nameInput : String
    , descriptionInput : String
    , urlInput : String
    }


init : LoggedIn.Model -> ( Model, Cmd Msg )
init loggedIn =
    ( { logoUrl = Nothing
      , nameInput = ""
      , descriptionInput = ""
      , urlInput = ""
      }
    , LoggedIn.maybeInitWith CompletedLoadCommunity .selectedCommunity loggedIn
    )


defaultLogo : String
defaultLogo =
    "https://cambiatus-uploads.s3.amazonaws.com/cambiatus-uploads/community_2.png"



-- UPDATE


type Msg
    = CompletedLoadCommunity Community.Model
    | EnteredLogo (List File)
    | CompletedLogoUpload (Result Http.Error String)
    | EnteredName String
    | EnteredDescription String
    | EnteredUrl String
    | ClickedSave


type alias UpdateResult =
    UR.UpdateResult Model Msg (LoggedIn.External Msg)


update : Msg -> Model -> LoggedIn.Model -> UpdateResult
update msg model loggedIn =
    case msg of
        CompletedLoadCommunity community ->
            { model
                | logoUrl = Just community.logo
                , nameInput = community.name
                , descriptionInput = community.description

                -- TODO - use community subdomain
                , urlInput = String.toLower community.name
            }
                |> UR.init

        EnteredLogo (file :: _) ->
            UR.init model
                |> UR.addCmd (Api.uploadImage loggedIn.shared file CompletedLogoUpload)

        -- TODO
        EnteredLogo [] ->
            UR.init model

        CompletedLogoUpload (Ok url) ->
            { model | logoUrl = Just url }
                |> UR.init

        CompletedLogoUpload (Err _) ->
            -- TODO - Show error
            UR.init model

        EnteredName name ->
            { model | nameInput = name }
                |> UR.init

        EnteredDescription description ->
            { model | descriptionInput = description }
                |> UR.init

        EnteredUrl url ->
            { model | urlInput = url }
                |> UR.init

        ClickedSave ->
            UR.init model



-- VIEW


view : LoggedIn.Model -> Model -> { title : String, content : Html Msg }
view ({ shared } as loggedIn) model =
    let
        { t } =
            shared.translators

        title =
            t "settings.community_info.title"

        content =
            case loggedIn.selectedCommunity of
                RemoteData.Failure e ->
                    Page.fullPageGraphQLError title e

                RemoteData.Loading ->
                    Page.fullPageLoading shared

                RemoteData.NotAsked ->
                    Page.fullPageLoading shared

                RemoteData.Success _ ->
                    div [ class "bg-white" ]
                        [ Page.viewHeader loggedIn title Route.CommunitySettings
                        , view_ loggedIn model
                        ]
    in
    { title = title
    , content = content
    }


view_ : LoggedIn.Model -> Model -> Html Msg
view_ loggedIn model =
    let
        { t } =
            loggedIn.shared.translators
    in
    form
        [ class "w-full px-4 pb-10"
        , onSubmit ClickedSave
        ]
        [ div [ class "container mx-auto pt-4" ]
            [ div [ class "space-y-10" ]
                [ viewLogo loggedIn.shared model
                , viewName loggedIn.shared model
                , viewDescription loggedIn.shared model
                , viewUrl loggedIn.shared model
                ]
            , button [ class "button button-primary w-full mt-8" ] [ text (t "menu.save") ]
            ]
        ]


viewLogo : Shared -> Model -> Html Msg
viewLogo shared model =
    let
        text_ =
            text << shared.translators.t

        logo =
            case model.logoUrl of
                Nothing ->
                    defaultLogo

                Just logoUrl ->
                    logoUrl
    in
    div []
        [ div [ class "input-label" ]
            [ text_ "settings.community_info.logo.title" ]
        , div [ class "mt-2 m-auto w-20 h-20 relative" ]
            [ input
                [ id "community-upload-logo"
                , class "profile-img-input"
                , type_ "file"
                , accept "image/*"
                , Page.onFileChange EnteredLogo
                , multiple False
                ]
                []
            , label
                [ for "community-upload-logo"
                , class "block cursor-pointer"
                ]
                [ img [ class "object-cover rounded-full w-20 h-20", src logo ] []
                , span [ class "absolute bottom-0 right-0 bg-orange-300 w-8 h-8 p-2 rounded-full" ] [ Icons.camera "" ]
                ]
            ]
        , div [ class "mt-4" ]
            [ div [ class "font-bold" ] [ text_ "settings.community_info.guidance" ]
            , div [ class "text-gray-600" ] [ text_ "settings.community_info.logo.description" ]
            ]
        ]


viewName : Shared -> Model -> Html Msg
viewName shared model =
    let
        { t } =
            shared.translators
    in
    View.Form.Input.init
        { label = t "settings.community_info.fields.name"
        , id = "community_name_input"
        , onInput = EnteredName
        , disabled = False
        , value = model.nameInput
        , placeholder = Just (t "settings.community_info.placeholders.name")
        , problems = Just [ "TODO" ]
        , translators = shared.translators
        }
        |> View.Form.Input.toHtml


viewDescription : Shared -> Model -> Html Msg
viewDescription shared model =
    let
        { t } =
            shared.translators
    in
    View.Form.Input.init
        { label = t "settings.community_info.fields.description"
        , id = "community_description_input"
        , onInput = EnteredDescription
        , disabled = False
        , value = model.descriptionInput
        , placeholder = Just (t "settings.community_info.placeholders.description")
        , problems = Just [ "TODO" ]
        , translators = shared.translators
        }
        |> View.Form.Input.toHtmlTextArea


viewUrl : Shared -> Model -> Html Msg
viewUrl shared model =
    let
        { t } =
            shared.translators

        text_ =
            text << t
    in
    div []
        [ View.Form.Input.init
            { label = t "settings.community_info.fields.url"
            , id = "community_description_input"
            , onInput = EnteredUrl
            , disabled = False
            , value = model.urlInput
            , placeholder = Just (t "settings.community_info.placeholders.url")
            , problems = Just [ "TODO" ]
            , translators = shared.translators
            }
            |> View.Form.Input.withCounter 30
            |> View.Form.Input.withAttrs [ maxlength 30 ]
            |> View.Form.Input.withElement (text ".cambiatus.io")
            |> View.Form.Input.toHtml
        , div [ class "font-bold" ] [ text_ "settings.community_info.guidance" ]
        , ul [ class "text-gray-600" ]
            [ ul []
                [ li [] [ text_ "settings.community_info.constraints.length" ]
                , li [] [ text_ "settings.community_info.constraints.characters" ]
                ]
            , ul [ class "mt-4" ]
                [ li [] [ text_ "settings.community_info.constraints.bad_words" ]
                , li [] [ text_ "settings.community_info.constraints.casing" ]
                , li [] [ text_ "settings.community_info.constraints.accents" ]
                ]
            ]
        ]



-- UTILS


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
        CompletedLoadCommunity _ ->
            [ "CompletedLoadCommunity" ]

        EnteredLogo _ ->
            [ "EnteredLogo" ]

        CompletedLogoUpload r ->
            [ "CompletedLogoUpload", UR.resultToString r ]

        EnteredName _ ->
            [ "EnteredName" ]

        EnteredDescription _ ->
            [ "EnteredDescription" ]

        EnteredUrl _ ->
            [ "EnteredUrl" ]

        ClickedSave ->
            [ "ClickedSave" ]
