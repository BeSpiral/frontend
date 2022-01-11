module View.Form.Input exposing
    ( init
    , withElements
    , withAttrs, withContainerAttrs
    , toHtml
    , CounterType(..), FieldType(..), InputType(..)
    )

{-| Creates a Cambiatus-style text input that supports error reporting, placeholders, localization
and character counters.

       View.Form.Input.init
           { label = "Username"
           , id = "username_input"
           , onInput = EnteredUsername
           , disabled = False
           , value = model.username
           , placeholder = "Enter your username"
           , problems = model.username\_problems
           , translators = shared.translators
           }
           |> View.Form.Input.withCounter 12
           |> View.Form.Input.toHtml


# Initializing

@docs init


# Helpers


## Adding elements

@docs withCounter, withElements


## Adding attributes

@docs withCounterAttrs, withErrorAttrs, withAttrs, withContainerAttrs, withLabelAttrs


## Changing types

@docs withInputType, withCounterType


# Converting to HTML

@docs toHtml

-}

import Html exposing (Html, div, li, text, ul)
import Html.Attributes exposing (class, classList, disabled, id, placeholder, type_, value)
import Html.Events exposing (onInput)
import I18Next
import Session.Shared exposing (Translators)
import View.Form


{-| Required options for an input
-}
type alias RequiredInputOptions a =
    { label : String
    , id : String
    , onInput : String -> a
    , disabled : Bool
    , value : String
    , placeholder : Maybe String
    , problems : Maybe (List String)
    , translators : Translators
    }


{-| Initializes an input
-}
init : RequiredInputOptions a -> InputOptions a
init options =
    { label = options.label
    , labelAttrs = []
    , id = options.id
    , onInput = options.onInput
    , disabled = options.disabled
    , value = options.value
    , placeholder = options.placeholder
    , problems = options.problems
    , maximumCounterValue = Nothing
    , translators = options.translators
    , extraAttrs = []
    , counterAttrs = []
    , containerAttrs = []
    , extraElements = []
    , errorAttrs = []
    , inputType = Input
    , fieldType = Text
    , counterType = CountLetters
    }


{-| Converts a Cambiatus input into Html to be used in view code
-}
toHtml : InputOptions a -> Html a
toHtml options =
    div
        (class "relative mb-10"
            :: options.containerAttrs
        )
        [ if String.isEmpty options.label then
            text ""

          else
            View.Form.label options.labelAttrs options.id options.label
        , input options
        , div [ class "flex w-full px-1" ]
            [ ul [ class "inline-block mr-auto" ]
                (options.problems
                    |> Maybe.withDefault []
                    |> List.map (viewFieldProblem options.errorAttrs)
                )
            , case options.maximumCounterValue of
                Just number ->
                    inputCounterviewWithAttrs options.translators.tr
                        number
                        options.value
                        options.counterAttrs
                        options.counterType

                Nothing ->
                    text ""
            ]
        ]


{-| Basic Cambiatus-style input
-}
input : InputOptions a -> Html a
input options =
    let
        ( inputElement, inputClass, typeAttr ) =
            ( Html.input, "input", type_ "text" )
    in
    div [ class "relative" ]
        (inputElement
            (id options.id
                :: onInput options.onInput
                :: class ("w-full " ++ inputClass)
                :: classList [ ( "with-error", hasErrors options ) ]
                :: disabled options.disabled
                :: value options.value
                :: placeholder (Maybe.withDefault "" options.placeholder)
                :: typeAttr
                :: options.extraAttrs
            )
            []
            :: options.extraElements
        )


{-| Adds attributes to the input field
-}
withAttrs : List (Html.Attribute a) -> InputOptions a -> InputOptions a
withAttrs attrs options =
    { options | extraAttrs = options.extraAttrs ++ attrs }


{-| Adds attributes to the element that contains everything else
-}
withContainerAttrs : List (Html.Attribute a) -> InputOptions a -> InputOptions a
withContainerAttrs attrs options =
    { options | containerAttrs = options.containerAttrs ++ attrs }


{-| Adds an element to the input, so we can have elements inside the input

**Note**: the element isn't inside the input by default. You should use the
`absolute` class, along with other classes you may need to position the element

-}
withElements : List (Html a) -> InputOptions a -> InputOptions a
withElements elements options =
    { options | extraElements = elements ++ options.extraElements }


{-| Creates a Cambiatus-style input counter.
-}
inputCounterviewWithAttrs : (String -> I18Next.Replacements -> String) -> Int -> String -> List (Html.Attribute msg) -> CounterType -> Html msg
inputCounterviewWithAttrs tr max str attrs counterType =
    let
        currentLength =
            String.length str
    in
    div (class "text-purple-100 mt-2 ml-2 uppercase font-bold text-sm flex-shrink-0" :: attrs)
        [ text <|
            tr "edit.input_counter"
                [ ( "current", String.fromInt currentLength )
                , ( "max", String.fromInt max )
                ]
        ]


type CounterType
    = CountLetters



--- INTERNAL


hasErrors : InputOptions a -> Bool
hasErrors options =
    options.problems
        |> Maybe.withDefault []
        |> List.length
        |> (\length -> length > 0)


viewFieldProblem : List (Html.Attribute a) -> String -> Html a
viewFieldProblem attrs problem =
    li (class "form-error" :: attrs) [ text problem ]


type alias InputOptions a =
    { label : String
    , labelAttrs : List (Html.Attribute a)
    , id : String
    , onInput : String -> a
    , disabled : Bool
    , value : String
    , placeholder : Maybe String
    , problems : Maybe (List String)
    , translators : Translators
    , maximumCounterValue : Maybe Int
    , extraAttrs : List (Html.Attribute a)
    , counterAttrs : List (Html.Attribute a)
    , containerAttrs : List (Html.Attribute a)
    , extraElements : List (Html a)
    , errorAttrs : List (Html.Attribute a)
    , inputType : InputType
    , fieldType : FieldType
    , counterType : CounterType
    }


{-| All possible input types
-}
type InputType
    = Input


{-| Different possible type\_s
-}
type FieldType
    = Text
