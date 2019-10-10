-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Bespiral.Mutation exposing (ReadNotificationRequiredArguments, RegisterPushRequiredArguments, UpdateChatLanguageRequiredArguments, UpdateProfileRequiredArguments, readNotification, registerPush, updateChatLanguage, updateProfile)

import Bespiral.InputObject
import Bespiral.Interface
import Bespiral.Object
import Bespiral.Scalar
import Bespiral.ScalarCodecs
import Bespiral.Union
import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode as Decode exposing (Decoder)


type alias ReadNotificationRequiredArguments =
    { input : Bespiral.InputObject.ReadNotificationInput }


{-| Mark a notification history as read
-}
readNotification : ReadNotificationRequiredArguments -> SelectionSet decodesTo Bespiral.Object.NotificationHistory -> SelectionSet decodesTo RootMutation
readNotification requiredArgs object_ =
    Object.selectionForCompositeField "readNotification" [ Argument.required "input" requiredArgs.input Bespiral.InputObject.encodeReadNotificationInput ] object_ identity


type alias RegisterPushRequiredArguments =
    { input : Bespiral.InputObject.PushSubscriptionInput }


{-| Register an push subscription on BeSpiral
-}
registerPush : RegisterPushRequiredArguments -> SelectionSet decodesTo Bespiral.Object.PushSubscription -> SelectionSet decodesTo RootMutation
registerPush requiredArgs object_ =
    Object.selectionForCompositeField "registerPush" [ Argument.required "input" requiredArgs.input Bespiral.InputObject.encodePushSubscriptionInput ] object_ identity


type alias UpdateChatLanguageRequiredArguments =
    { input : Bespiral.InputObject.ChatUpdateInput }


{-| A mutation to update user's chat language
-}
updateChatLanguage : UpdateChatLanguageRequiredArguments -> SelectionSet decodesTo Bespiral.Object.ChatPreferences -> SelectionSet (Maybe decodesTo) RootMutation
updateChatLanguage requiredArgs object_ =
    Object.selectionForCompositeField "updateChatLanguage" [ Argument.required "input" requiredArgs.input Bespiral.InputObject.encodeChatUpdateInput ] object_ (identity >> Decode.nullable)


type alias UpdateProfileRequiredArguments =
    { input : Bespiral.InputObject.ProfileUpdateInput }


{-| A mutation to update a user's profile
-}
updateProfile : UpdateProfileRequiredArguments -> SelectionSet decodesTo Bespiral.Object.Profile -> SelectionSet (Maybe decodesTo) RootMutation
updateProfile requiredArgs object_ =
    Object.selectionForCompositeField "updateProfile" [ Argument.required "input" requiredArgs.input Bespiral.InputObject.encodeProfileUpdateInput ] object_ (identity >> Decode.nullable)
