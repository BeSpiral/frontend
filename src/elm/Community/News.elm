module Community.News exposing (Model, selectionSet, viewList)

import Cambiatus.Object
import Cambiatus.Object.News as News
import Cambiatus.Object.NewsVersion as Version
import Cambiatus.Scalar
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Html exposing (Html, a, div, h2, p, span, text)
import Html.Attributes exposing (class, classList, style)
import Icons
import Iso8601
import List.Extra
import Profile
import Route
import Session.Shared exposing (Shared)
import Time
import Utils
import View.Components
import View.MarkdownEditor


type alias Model =
    { description : String
    , id : Int
    , title : String
    , scheduling : Maybe Time.Posix
    , insertedAt : Time.Posix
    , updatedAt : Time.Posix
    , lastEditor : Maybe Profile.Minimal
    }


selectionSet : SelectionSet Model Cambiatus.Object.News
selectionSet =
    SelectionSet.succeed Model
        |> SelectionSet.with News.description
        |> SelectionSet.with News.id
        |> SelectionSet.with News.title
        |> SelectionSet.with
            (News.scheduling
                |> SelectionSet.map
                    (Maybe.andThen
                        (\(Cambiatus.Scalar.DateTime dateTime) ->
                            Iso8601.toTime dateTime
                                |> Result.toMaybe
                        )
                    )
            )
        |> SelectionSet.with
            (News.insertedAt
                |> SelectionSet.map timeFromNaiveDateTime
            )
        |> SelectionSet.with
            (News.updatedAt
                |> SelectionSet.map timeFromNaiveDateTime
            )
        |> SelectionSet.with
            (News.versions
                (Version.user Profile.minimalSelectionSet)
                |> SelectionSet.map (List.filterMap identity >> List.head)
            )


timeFromNaiveDateTime : Cambiatus.Scalar.NaiveDateTime -> Time.Posix
timeFromNaiveDateTime (Cambiatus.Scalar.NaiveDateTime dateTime) =
    Iso8601.toTime dateTime
        |> Result.withDefault (Time.millisToPosix 0)


viewList : Shared -> List (Html.Attribute msg) -> List Model -> Html msg
viewList shared attrs news =
    div (class "divide-y divide-gray-500 space-y-4" :: attrs)
        (news
            |> List.Extra.groupWhile
                (\news1 news2 ->
                    Utils.areSameDay shared.timezone
                        news1.insertedAt
                        news2.insertedAt
                )
            |> List.map
                (\( firstNews, otherNews ) ->
                    div [ class "pt-4 first:pt-0" ]
                        [ View.Components.dateViewer
                            [ class "text-black text-sm font-bold uppercase" ]
                            identity
                            shared
                            firstNews.insertedAt
                        , div [ class "divide-y divide-gray-500" ]
                            (List.map
                                (\theseNews ->
                                    -- TODO - Use real data for hasRead
                                    viewSummary (modBy 2 theseNews.id == 0)
                                        theseNews
                                )
                                (firstNews :: otherNews)
                            )
                        ]
                )
        )


viewSummary : Bool -> Model -> Html msg
viewSummary hasRead news =
    a
        [ class "grid items-center py-4 focus-ring rounded-sm"
        , classList
            [ ( "text-gray-900 hover:text-gray-400", hasRead )
            , ( "text-purple-500 hover:opacity-80", not hasRead )
            ]
        , style "grid-template-columns" "28px 1fr 80px"
        , Route.href (Route.News (Just news.id))
        ]
        [ Icons.speechBubble "flex-shrink-0 stroke-current"
        , div [ class "truncate ml-4 mr-16" ]
            [ h2 [ class "font-bold truncate" ] [ text news.title ]
            , p [ class "truncate" ]
                [ text <| View.MarkdownEditor.removeFormatting news.description ]
            ]
        , if not hasRead then
            span
                [ class "button button-primary w-auto px-4"
                ]
                -- TODO - I18N
                [ text "Read" ]

          else
            Icons.arrowDown "-rotate-90 fill-current ml-auto"
        ]
