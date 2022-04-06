module View.Components exposing
    ( loadingLogoAnimated, loadingLogoAnimatedFluid, loadingLogoWithCustomText
    , dialogBubble, masonryLayout, Breakpoint(..)
    , tooltip, pdfViewer, dateViewer, infiniteList, ElementToTrack(..), label, disablableLink
    , bgNoScroll, PreventScroll(..), keyListener, Key(..), focusTrap, intersectionObserver
    )

{-| This module exports some simple components that don't need to manage any
state or configuration, such as loading indicators and containers


# Loading

@docs loadingLogoAnimated, loadingLogoAnimatedFluid, loadingLogoWithCustomText


# Containers

@docs dialogBubble, masonryLayout, Breakpoint


## Helper types

@docs Orientation


# Elements

@docs tooltip, pdfViewer, dateViewer, infiniteList, ElementToTrack, label, disablableLink


# Helpers

@docs bgNoScroll, PreventScroll, keyListener, Key, focusTrap, intersectionObserver

-}

import Html exposing (Html, div, img, node, p, span, text)
import Html.Attributes exposing (attribute, class, for, src)
import Html.Events exposing (on)
import Icons
import Json.Decode
import Time
import Translation exposing (Translators)
import Utils



-- LOADING


loadingLogoAnimated : Translators -> String -> Html msg
loadingLogoAnimated translators class_ =
    loadingLogoWithCustomText translators "loading.subtitle" class_


loadingLogoWithCustomText : Translators -> String -> String -> Html msg
loadingLogoWithCustomText { t } customTextKey class_ =
    div [ class ("w-full text-center " ++ class_) ]
        [ img [ class "h-16 mx-auto mt-8", src "/images/loading.svg" ] []
        , p [ class "font-bold text-xl" ] [ text <| t "loading.title" ]
        , p [ class "text-sm" ] [ text <| t customTextKey ]
        ]


{-| A fluid-size loading indicator, fills the space as much as possible
-}
loadingLogoAnimatedFluid : Html msg
loadingLogoAnimatedFluid =
    div [ class "w-full text-center h-full py-2" ]
        [ img [ class "mx-auto h-full", src "/images/loading.svg" ] [] ]



-- CONTAINERS


dialogBubble :
    { class_ : String
    , relativeSelector : Maybe String
    , scrollSelector : Maybe String
    }
    -> List (Html msg)
    -> Html msg
dialogBubble { class_, relativeSelector, scrollSelector } elements =
    node "dialog-bubble"
        [ attribute "elm-class" class_
        , optionalAttr "elm-relative-selector" relativeSelector
        , optionalAttr "elm-scroll-selector" scrollSelector
        ]
        elements


type Breakpoint
    = Lg
    | Xl


{-| Create a masonry layout, similar to Pinterest. This uses CSS Grid + some JS
magic. If you're changing `gap-y` or `auto-rows`, test it very well, since the
accuracy of this component depends on those properties. If you want vertical
gutters, give each child element a `mb-*` class and this element a negative bottom margin.

You must provide at least one `Breakpoint` to specify screen sizes this should
work as a masonry layout.

-}
masonryLayout :
    List Breakpoint
    -> List (Html.Attribute msg)
    -> List (Html msg)
    -> Html msg
masonryLayout breakpoints attrs children =
    let
        classesForBreakpoint breakpoint =
            case breakpoint of
                Lg ->
                    -- Tailwind might purge if we do something with List.map instead of explicitly writing these
                    "lg:gap-y-0 lg:grid lg:auto-rows-[1px]"

                Xl ->
                    "xl:gap-y-0 xl:grid xl:auto-rows-[1px]"
    in
    node "masonry-layout"
        ((List.map classesForBreakpoint breakpoints
            |> String.join " "
            |> class
         )
            :: attrs
        )
        children



-- ELEMENTS


tooltip : { message : String, iconClass : String } -> Html msg
tooltip { message, iconClass } =
    span [ class "icon-tooltip ml-1 z-10" ]
        [ Icons.question ("inline-block " ++ iconClass)
        , p [ class "icon-tooltip-content" ]
            [ text message ]
        ]


{-| Display a PDF coming from a url. If the PDF cannot be read, display an `img`
with `url` as `src`. This element automatically shows a loading animation while
it fetches the pdf. If you pass in `Translators`, there will also be a text
under the loading animation
-}
pdfViewer : List (Html.Attribute msg) -> { url : String, childClass : String, maybeTranslators : Maybe Translators } -> Html msg
pdfViewer attrs { url, childClass, maybeTranslators } =
    let
        loadingAttributes =
            case maybeTranslators of
                Nothing ->
                    []

                Just { t } ->
                    [ attribute "elm-loading-title" (t "loading.title")
                    , attribute "elm-loading-subtitle" (t "loading.subtitle")
                    ]
    in
    node "pdf-viewer"
        (attribute "elm-url" url
            :: attribute "elm-child-class" childClass
            :: class "flex flex-col items-center justify-center"
            :: loadingAttributes
            ++ attrs
        )
        []


type alias DateTranslations =
    { today : Maybe String
    , yesterday : Maybe String
    , other : String
    }


{-| A helper to display dates. Supports providing your own translated strings
for when the date is today or yesterday

    dateViewer []
        (\translations ->
            { translations
                | today = t "claim.claimed_today"
                , yesterday = t "claim.claimed_yesterday"
                , other = "claim.claimed_on"
            }
        )
        shared
        claim.claimDate

The `other` key on the translations record needs a `{{date}}` somewhere in the
string so we can replace it on JS

-}
dateViewer :
    List (Html.Attribute msg)
    -> (DateTranslations -> DateTranslations)
    ->
        { shared
            | now : Time.Posix
            , timezone : Time.Zone
            , translators : Translators
            , language : Translation.Language
        }
    -> Time.Posix
    -> Html msg
dateViewer attrs fillInTranslations shared time =
    let
        yesterday =
            Utils.previousDay shared.now

        translations =
            fillInTranslations
                { today = Just (shared.translators.t "dates.today")
                , yesterday = Just (shared.translators.t "dates.yesterday")
                , other = "{{date}}"
                }

        translationString =
            if Utils.areSameDay shared.timezone shared.now time then
                translations.today
                    |> Maybe.withDefault translations.other

            else if Utils.areSameDay shared.timezone shared.now yesterday then
                translations.yesterday
                    |> Maybe.withDefault translations.other

            else
                translations.other
    in
    if String.contains "{{date}}" translationString then
        dateFormatter attrs
            { language = shared.language
            , date = time
            , translationString = translationString
            }

    else if Utils.areSameDay shared.timezone shared.now time then
        span attrs [ text (Maybe.withDefault translations.other translations.today) ]

    else if Utils.areSameDay shared.timezone shared.now yesterday then
        span attrs [ text (Maybe.withDefault translations.other translations.yesterday) ]

    else
        text ""


type ElementToTrack
    = TrackSelf
    | TrackWindow
    | TrackSelector String


{-| An infinite list component. It automatically requests more items as the user
scrolls down, based on a `distanceToRequest`, which is the distance to the
bottom of the container. If you don't want to request more items (i.e. when
there are no more items), just pass `requestedItems = Nothing`.
-}
infiniteList :
    { onRequestedItems : Maybe msg
    , distanceToRequest : Int
    , elementToTrack : ElementToTrack
    }
    -> List (Html.Attribute msg)
    -> List (Html msg)
    -> Html msg
infiniteList options attrs children =
    let
        requestedItemsListener =
            case options.onRequestedItems of
                Nothing ->
                    class ""

                Just onRequestedItems ->
                    on "requested-items" (Json.Decode.succeed onRequestedItems)

        elementToTrackToString elementToTrack =
            case elementToTrack of
                TrackWindow ->
                    "track-window"

                TrackSelf ->
                    "track-self"

                TrackSelector selector ->
                    selector
    in
    node "infinite-list"
        (requestedItemsListener
            :: class "overflow-y-auto inline-block"
            :: attribute "elm-distance-to-request" (String.fromInt options.distanceToRequest)
            :: attribute "elm-element-to-track" (elementToTrackToString options.elementToTrack)
            :: attrs
        )
        children


{-| A label element that enforces the label has an id to point to
-}
label : List (Html.Attribute msg) -> { targetId : String, labelText : String } -> Html msg
label attrs { targetId, labelText } =
    Html.label (class "label" :: for targetId :: attrs)
        [ text labelText
        ]


{-| An element that acts as a link when it's not disabled, or as regular text when it is disabled.
No styling is done, so you need to do it yourself wherever you're using this component, usually with `classList`:

    disablableLink { isDisabled = isDisabled }
        [ Route.href Route.Transfer
        , class "button button-primary"
        , classList [ ( "button-disabled", isDisabled ) ]
        ]
        [ text "Transfer to a friend " ]

-}
disablableLink : { isDisabled : Bool } -> List (Html.Attribute msg) -> List (Html msg) -> Html msg
disablableLink { isDisabled } =
    if isDisabled then
        span

    else
        Html.a



-- HELPERS


{-| A node that prevents the body from scrolling
-}
bgNoScroll : List (Html.Attribute msg) -> PreventScroll -> Html msg
bgNoScroll attrs preventScroll =
    let
        preventScrollClass =
            case preventScroll of
                PreventScrollOnMobile ->
                    "overflow-hidden md:overflow-auto"

                PreventScrollAlways ->
                    "overflow-hidden"
    in
    node "bg-no-scroll"
        (attribute "elm-prevent-scroll-class" preventScrollClass
            :: attrs
        )
        []


type PreventScroll
    = PreventScrollOnMobile
    | PreventScrollAlways


type Key
    = Escape
    | Enter
    | Space
    | ArrowUp
    | ArrowDown
    | ArrowLeft
    | ArrowRight


{-| A node that attaches an event listener on the document to listen for keys.
Useful when we want to listen for keypresses, but don't want to use
subscriptions (because it would add a lot of complexity). Can be useful in
"stateless" components, such as modals.
-}
keyListener :
    { acceptedKeys : List Key
    , toMsg : Key -> msg
    , stopPropagation : Bool
    , preventDefault : Bool
    }
    -> Html msg
keyListener { acceptedKeys, toMsg, stopPropagation, preventDefault } =
    let
        keyFromString : String -> Maybe Key
        keyFromString rawKey =
            case String.toLower rawKey of
                "esc" ->
                    Just Escape

                "escape" ->
                    Just Escape

                " " ->
                    Just Space

                "enter" ->
                    Just Enter

                "arrowup" ->
                    Just ArrowUp

                "arrowdown" ->
                    Just ArrowDown

                "arrowleft" ->
                    Just ArrowLeft

                "arrowright" ->
                    Just ArrowRight

                _ ->
                    Nothing

        keyToString : Key -> List String
        keyToString key =
            case key of
                Escape ->
                    [ "esc", "escape" ]

                Space ->
                    [ " " ]

                Enter ->
                    [ "enter" ]

                ArrowUp ->
                    [ "arrowup" ]

                ArrowDown ->
                    [ "arrowdown" ]

                ArrowLeft ->
                    [ "arrowleft" ]

                ArrowRight ->
                    [ "arrowright" ]

        keyDecoder : List Key -> (Key -> msg) -> Json.Decode.Decoder msg
        keyDecoder acceptedKeys_ toMsg_ =
            Json.Decode.at [ "detail", "key" ] Json.Decode.string
                |> Json.Decode.andThen
                    (\rawKey ->
                        case keyFromString rawKey of
                            Just key ->
                                if List.member key acceptedKeys_ then
                                    Json.Decode.succeed (toMsg_ key)

                                else
                                    Json.Decode.fail "This key is not being listened to"

                            Nothing ->
                                Json.Decode.fail "The given key is not registered as a Key that the keyListener can listen to"
                    )
    in
    node "key-listener"
        [ on "listener-keydown" (keyDecoder acceptedKeys toMsg)
        , attribute "keydown-stop-propagation" (boolToString stopPropagation)
        , attribute "keydown-prevent-default" (boolToString preventDefault)
        , attribute "accepted-keys"
            (acceptedKeys
                |> List.concatMap keyToString
                |> String.join ","
            )
        ]
        []


focusTrap : { firstFocusContainer : Maybe String } -> List (Html.Attribute msg) -> List (Html msg) -> Html msg
focusTrap { firstFocusContainer } attrs children =
    node "focus-trap"
        (optionalAttr "first-focus-container" firstFocusContainer :: attrs)
        children


{-| A wrapper around the intersection observer API. Note that targetSelector is
a `String` that works with the `querySelector` API, so if you want to get an element
by id you need to use `#` as a prefix.
-}
intersectionObserver :
    { targetSelectors : List String
    , threshold : Float
    , onStartedIntersecting : String -> msg
    }
    -> Html msg
intersectionObserver options =
    node "intersection-observer"
        [ attribute "elm-target" (String.join " " options.targetSelectors)
        , attribute "elm-threshold" (String.fromFloat options.threshold)
        , on "started-intersecting"
            (Json.Decode.at [ "detail", "targetId" ] Json.Decode.string
                |> Json.Decode.andThen
                    (\targetId ->
                        Json.Decode.succeed (options.onStartedIntersecting targetId)
                    )
            )
        ]
        []



-- INTERNALS


boolToString : Bool -> String
boolToString b =
    if b then
        "true"

    else
        "false"


optionalAttr : String -> Maybe String -> Html.Attribute msg
optionalAttr attr maybeAttr =
    case maybeAttr of
        Nothing ->
            class ""

        Just attrValue ->
            attribute attr attrValue


dateFormatter :
    List (Html.Attribute msg)
    -> { language : Translation.Language, date : Time.Posix, translationString : String }
    -> Html msg
dateFormatter attrs { language, date, translationString } =
    node "date-formatter"
        (attribute "elm-locale" (Translation.languageToLocale language)
            :: attribute "elm-date" (date |> Time.posixToMillis |> String.fromInt)
            :: attribute "elm-translation" translationString
            :: attrs
        )
        []
