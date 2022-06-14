-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Cambiatus.Mutation exposing (..)

import Cambiatus.Enum.CurrencyType
import Cambiatus.Enum.Language
import Cambiatus.Enum.ReactionEnum
import Cambiatus.InputObject
import Cambiatus.Interface
import Cambiatus.Object
import Cambiatus.Scalar
import Cambiatus.ScalarCodecs
import Cambiatus.Union
import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode as Decode exposing (Decoder)


{-| [Auth required] Set the latest\_accept\_terms date
-}
acceptTerms :
    SelectionSet decodesTo Cambiatus.Object.User
    -> SelectionSet (Maybe decodesTo) RootMutation
acceptTerms object_ =
    Object.selectionForCompositeField "acceptTerms" [] object_ (identity >> Decode.nullable)


type alias AddCommunityPhotosRequiredArguments =
    { symbol : String
    , urls : List String
    }


{-| [Auth required - Admin only] Adds photos of a community
-}
addCommunityPhotos :
    AddCommunityPhotosRequiredArguments
    -> SelectionSet decodesTo Cambiatus.Object.Community
    -> SelectionSet (Maybe decodesTo) RootMutation
addCommunityPhotos requiredArgs object_ =
    Object.selectionForCompositeField "addCommunityPhotos" [ Argument.required "symbol" requiredArgs.symbol Encode.string, Argument.required "urls" requiredArgs.urls (Encode.string |> Encode.list) ] object_ (identity >> Decode.nullable)


type alias CategoryOptionalArguments =
    { categories : OptionalArgument (List Cambiatus.InputObject.SubcategoryInput)
    , description : OptionalArgument String
    , iconUri : OptionalArgument String
    , id : OptionalArgument Int
    , imageUri : OptionalArgument String
    , metaDescription : OptionalArgument String
    , metaKeywords : OptionalArgument String
    , metaTitle : OptionalArgument String
    , name : OptionalArgument String
    , parentId : OptionalArgument Int
    , slug : OptionalArgument String
    }


{-| [Auth required - Admin only] Upserts a category

  - categories - List of subcategories; Associates given IDs as subcategories to this category
  - parentId - Parent category ID

-}
category :
    (CategoryOptionalArguments -> CategoryOptionalArguments)
    -> SelectionSet decodesTo Cambiatus.Object.Category
    -> SelectionSet (Maybe decodesTo) RootMutation
category fillInOptionals object_ =
    let
        filledInOptionals =
            fillInOptionals { categories = Absent, description = Absent, iconUri = Absent, id = Absent, imageUri = Absent, metaDescription = Absent, metaKeywords = Absent, metaTitle = Absent, name = Absent, parentId = Absent, slug = Absent }

        optionalArgs =
            [ Argument.optional "categories" filledInOptionals.categories (Cambiatus.InputObject.encodeSubcategoryInput |> Encode.list), Argument.optional "description" filledInOptionals.description Encode.string, Argument.optional "iconUri" filledInOptionals.iconUri Encode.string, Argument.optional "id" filledInOptionals.id Encode.int, Argument.optional "imageUri" filledInOptionals.imageUri Encode.string, Argument.optional "metaDescription" filledInOptionals.metaDescription Encode.string, Argument.optional "metaKeywords" filledInOptionals.metaKeywords Encode.string, Argument.optional "metaTitle" filledInOptionals.metaTitle Encode.string, Argument.optional "name" filledInOptionals.name Encode.string, Argument.optional "parentId" filledInOptionals.parentId Encode.int, Argument.optional "slug" filledInOptionals.slug Encode.string ]
                |> List.filterMap identity
    in
    Object.selectionForCompositeField "category" optionalArgs object_ (identity >> Decode.nullable)


type alias CommunityRequiredArguments =
    { communityId : String
    , input : Cambiatus.InputObject.CommunityUpdateInput
    }


{-| [Auth required - Admin only] Updates various fields in a community
-}
community :
    CommunityRequiredArguments
    -> SelectionSet decodesTo Cambiatus.Object.Community
    -> SelectionSet (Maybe decodesTo) RootMutation
community requiredArgs object_ =
    Object.selectionForCompositeField "community" [ Argument.required "communityId" requiredArgs.communityId Encode.string, Argument.required "input" requiredArgs.input Cambiatus.InputObject.encodeCommunityUpdateInput ] object_ (identity >> Decode.nullable)


type alias CompleteObjectiveRequiredArguments =
    { id : Int }


{-| [Auth required - Admin only] Complete an objective
-}
completeObjective :
    CompleteObjectiveRequiredArguments
    -> SelectionSet decodesTo Cambiatus.Object.Objective
    -> SelectionSet (Maybe decodesTo) RootMutation
completeObjective requiredArgs object_ =
    Object.selectionForCompositeField "completeObjective" [ Argument.required "id" requiredArgs.id Encode.int ] object_ (identity >> Decode.nullable)


type alias ContributionRequiredArguments =
    { amount : Float
    , communityId : String
    , currency : Cambiatus.Enum.CurrencyType.CurrencyType
    }


{-| [Auth required] Create a new contribution
-}
contribution :
    ContributionRequiredArguments
    -> SelectionSet decodesTo Cambiatus.Object.Contribution
    -> SelectionSet (Maybe decodesTo) RootMutation
contribution requiredArgs object_ =
    Object.selectionForCompositeField "contribution" [ Argument.required "amount" requiredArgs.amount Encode.float, Argument.required "communityId" requiredArgs.communityId Encode.string, Argument.required "currency" requiredArgs.currency (Encode.enum Cambiatus.Enum.CurrencyType.toString) ] object_ (identity >> Decode.nullable)


{-| [Auth required] A mutation to delete user's address data
-}
deleteAddress :
    SelectionSet decodesTo Cambiatus.Object.DeleteStatus
    -> SelectionSet (Maybe decodesTo) RootMutation
deleteAddress object_ =
    Object.selectionForCompositeField "deleteAddress" [] object_ (identity >> Decode.nullable)


type alias DeleteCategoryRequiredArguments =
    { id : Int }


{-| [Auth required - Admin only] Deletes a category
-}
deleteCategory :
    DeleteCategoryRequiredArguments
    -> SelectionSet decodesTo Cambiatus.Object.DeleteStatus
    -> SelectionSet (Maybe decodesTo) RootMutation
deleteCategory requiredArgs object_ =
    Object.selectionForCompositeField "deleteCategory" [ Argument.required "id" requiredArgs.id Encode.int ] object_ (identity >> Decode.nullable)


{-| [Auth required] A mutation to delete user's kyc data
-}
deleteKyc :
    SelectionSet decodesTo Cambiatus.Object.DeleteStatus
    -> SelectionSet (Maybe decodesTo) RootMutation
deleteKyc object_ =
    Object.selectionForCompositeField "deleteKyc" [] object_ (identity >> Decode.nullable)


type alias DeleteNewsRequiredArguments =
    { newsId : Int }


{-| [Auth required] Deletes News
-}
deleteNews :
    DeleteNewsRequiredArguments
    -> SelectionSet decodesTo Cambiatus.Object.DeleteStatus
    -> SelectionSet (Maybe decodesTo) RootMutation
deleteNews requiredArgs object_ =
    Object.selectionForCompositeField "deleteNews" [ Argument.required "newsId" requiredArgs.newsId Encode.int ] object_ (identity >> Decode.nullable)


type alias DeleteProductRequiredArguments =
    { id : Int }


{-| [Auth required] Deletes a product
-}
deleteProduct :
    DeleteProductRequiredArguments
    -> SelectionSet decodesTo Cambiatus.Object.DeleteStatus
    -> SelectionSet (Maybe decodesTo) RootMutation
deleteProduct requiredArgs object_ =
    Object.selectionForCompositeField "deleteProduct" [ Argument.required "id" requiredArgs.id Encode.int ] object_ (identity >> Decode.nullable)


type alias GenAuthRequiredArguments =
    { account : String }


{-| Generates a new signIn request
-}
genAuth :
    GenAuthRequiredArguments
    -> SelectionSet decodesTo Cambiatus.Object.Request
    -> SelectionSet decodesTo RootMutation
genAuth requiredArgs object_ =
    Object.selectionForCompositeField "genAuth" [ Argument.required "account" requiredArgs.account Encode.string ] object_ identity


type alias HighlightedNewsOptionalArguments =
    { newsId : OptionalArgument Int }


type alias HighlightedNewsRequiredArguments =
    { communityId : String }


{-| [Auth required - Admin only] Set highlighted news of community. If news\_id is not present, sets highlighted as nil
-}
highlightedNews :
    (HighlightedNewsOptionalArguments -> HighlightedNewsOptionalArguments)
    -> HighlightedNewsRequiredArguments
    -> SelectionSet decodesTo Cambiatus.Object.Community
    -> SelectionSet (Maybe decodesTo) RootMutation
highlightedNews fillInOptionals requiredArgs object_ =
    let
        filledInOptionals =
            fillInOptionals { newsId = Absent }

        optionalArgs =
            [ Argument.optional "newsId" filledInOptionals.newsId Encode.int ]
                |> List.filterMap identity
    in
    Object.selectionForCompositeField "highlightedNews" (optionalArgs ++ [ Argument.required "communityId" requiredArgs.communityId Encode.string ]) object_ (identity >> Decode.nullable)


type alias NewsOptionalArguments =
    { communityId : OptionalArgument String
    , id : OptionalArgument Int
    , scheduling : OptionalArgument Cambiatus.ScalarCodecs.DateTime
    }


type alias NewsRequiredArguments =
    { description : String
    , title : String
    }


{-| [Auth required - Admin only] News mutation, that allows for creating news on a community
-}
news :
    (NewsOptionalArguments -> NewsOptionalArguments)
    -> NewsRequiredArguments
    -> SelectionSet decodesTo Cambiatus.Object.News
    -> SelectionSet (Maybe decodesTo) RootMutation
news fillInOptionals requiredArgs object_ =
    let
        filledInOptionals =
            fillInOptionals { communityId = Absent, id = Absent, scheduling = Absent }

        optionalArgs =
            [ Argument.optional "communityId" filledInOptionals.communityId Encode.string, Argument.optional "id" filledInOptionals.id Encode.int, Argument.optional "scheduling" filledInOptionals.scheduling (Cambiatus.ScalarCodecs.codecs |> Cambiatus.Scalar.unwrapEncoder .codecDateTime) ]
                |> List.filterMap identity
    in
    Object.selectionForCompositeField "news" (optionalArgs ++ [ Argument.required "description" requiredArgs.description Encode.string, Argument.required "title" requiredArgs.title Encode.string ]) object_ (identity >> Decode.nullable)


type alias PreferenceOptionalArguments =
    { claimNotification : OptionalArgument Bool
    , digest : OptionalArgument Bool
    , language : OptionalArgument Cambiatus.Enum.Language.Language
    , transferNotification : OptionalArgument Bool
    }


{-| [Auth required] A mutation to only the preferences of the logged user
-}
preference :
    (PreferenceOptionalArguments -> PreferenceOptionalArguments)
    -> SelectionSet decodesTo Cambiatus.Object.User
    -> SelectionSet (Maybe decodesTo) RootMutation
preference fillInOptionals object_ =
    let
        filledInOptionals =
            fillInOptionals { claimNotification = Absent, digest = Absent, language = Absent, transferNotification = Absent }

        optionalArgs =
            [ Argument.optional "claimNotification" filledInOptionals.claimNotification Encode.bool, Argument.optional "digest" filledInOptionals.digest Encode.bool, Argument.optional "language" filledInOptionals.language (Encode.enum Cambiatus.Enum.Language.toString), Argument.optional "transferNotification" filledInOptionals.transferNotification Encode.bool ]
                |> List.filterMap identity
    in
    Object.selectionForCompositeField "preference" optionalArgs object_ (identity >> Decode.nullable)


type alias ProductOptionalArguments =
    { categories : OptionalArgument (List Int)
    , communityId : OptionalArgument String
    , description : OptionalArgument String
    , id : OptionalArgument Int
    , images : OptionalArgument (List String)
    , price : OptionalArgument Float
    , title : OptionalArgument String
    , trackStock : OptionalArgument Bool
    , units : OptionalArgument Int
    }


{-| [Auth required] Upserts a product

  - categories - List of categories ID you want to relate to this product

-}
product :
    (ProductOptionalArguments -> ProductOptionalArguments)
    -> SelectionSet decodesTo Cambiatus.Object.Product
    -> SelectionSet (Maybe decodesTo) RootMutation
product fillInOptionals object_ =
    let
        filledInOptionals =
            fillInOptionals { categories = Absent, communityId = Absent, description = Absent, id = Absent, images = Absent, price = Absent, title = Absent, trackStock = Absent, units = Absent }

        optionalArgs =
            [ Argument.optional "categories" filledInOptionals.categories (Encode.int |> Encode.list), Argument.optional "communityId" filledInOptionals.communityId Encode.string, Argument.optional "description" filledInOptionals.description Encode.string, Argument.optional "id" filledInOptionals.id Encode.int, Argument.optional "images" filledInOptionals.images (Encode.string |> Encode.list), Argument.optional "price" filledInOptionals.price Encode.float, Argument.optional "title" filledInOptionals.title Encode.string, Argument.optional "trackStock" filledInOptionals.trackStock Encode.bool, Argument.optional "units" filledInOptionals.units Encode.int ]
                |> List.filterMap identity
    in
    Object.selectionForCompositeField "product" optionalArgs object_ (identity >> Decode.nullable)


type alias ReactToNewsRequiredArguments =
    { newsId : Int
    , reactions : List Cambiatus.Enum.ReactionEnum.ReactionEnum
    }


{-| [Auth required] Add or update reactions from user in a news through news\_receipt
-}
reactToNews :
    ReactToNewsRequiredArguments
    -> SelectionSet decodesTo Cambiatus.Object.NewsReceipt
    -> SelectionSet (Maybe decodesTo) RootMutation
reactToNews requiredArgs object_ =
    Object.selectionForCompositeField "reactToNews" [ Argument.required "newsId" requiredArgs.newsId Encode.int, Argument.required "reactions" requiredArgs.reactions (Encode.enum Cambiatus.Enum.ReactionEnum.toString |> Encode.list) ] object_ (identity >> Decode.nullable)


type alias ReadRequiredArguments =
    { newsId : Int }


{-| [Auth required] Mark news as read, creating a new news\_receipt without reactions
-}
read :
    ReadRequiredArguments
    -> SelectionSet decodesTo Cambiatus.Object.NewsReceipt
    -> SelectionSet (Maybe decodesTo) RootMutation
read requiredArgs object_ =
    Object.selectionForCompositeField "read" [ Argument.required "newsId" requiredArgs.newsId Encode.int ] object_ (identity >> Decode.nullable)


type alias ReadNotificationRequiredArguments =
    { input : Cambiatus.InputObject.ReadNotificationInput }


{-| [Auth required] Mark a notification history as read
-}
readNotification :
    ReadNotificationRequiredArguments
    -> SelectionSet decodesTo Cambiatus.Object.NotificationHistory
    -> SelectionSet decodesTo RootMutation
readNotification requiredArgs object_ =
    Object.selectionForCompositeField "readNotification" [ Argument.required "input" requiredArgs.input Cambiatus.InputObject.encodeReadNotificationInput ] object_ identity


type alias RegisterPushRequiredArguments =
    { input : Cambiatus.InputObject.PushSubscriptionInput }


{-| [Auth required] Register an push subscription on Cambiatus
-}
registerPush :
    RegisterPushRequiredArguments
    -> SelectionSet decodesTo Cambiatus.Object.PushSubscription
    -> SelectionSet decodesTo RootMutation
registerPush requiredArgs object_ =
    Object.selectionForCompositeField "registerPush" [ Argument.required "input" requiredArgs.input Cambiatus.InputObject.encodePushSubscriptionInput ] object_ identity


type alias SignInOptionalArguments =
    { invitationId : OptionalArgument String }


type alias SignInRequiredArguments =
    { account : String
    , password : String
    }


{-| Sign In on the platform, gives back an access token

  - invitationId - Optional, used to auto invite an user to a community

-}
signIn :
    (SignInOptionalArguments -> SignInOptionalArguments)
    -> SignInRequiredArguments
    -> SelectionSet decodesTo Cambiatus.Object.Session
    -> SelectionSet decodesTo RootMutation
signIn fillInOptionals requiredArgs object_ =
    let
        filledInOptionals =
            fillInOptionals { invitationId = Absent }

        optionalArgs =
            [ Argument.optional "invitationId" filledInOptionals.invitationId Encode.string ]
                |> List.filterMap identity
    in
    Object.selectionForCompositeField "signIn" (optionalArgs ++ [ Argument.required "account" requiredArgs.account Encode.string, Argument.required "password" requiredArgs.password Encode.string ]) object_ identity


type alias SignUpOptionalArguments =
    { address : OptionalArgument Cambiatus.InputObject.AddressUpdateInput
    , invitationId : OptionalArgument String
    , kyc : OptionalArgument Cambiatus.InputObject.KycDataUpdateInput
    }


type alias SignUpRequiredArguments =
    { account : String
    , email : String
    , name : String
    , publicKey : String
    , userType : String
    }


{-| Creates a new user account

  - account - EOS Account, must have 12 chars long and use only [a-z] and [0-5]
  - address - Optional, Address data
  - email - User's email
  - invitationId - Optional, used to auto invite an user to a community
  - kyc - Optional, KYC data
  - name - User's Full name
  - publicKey - EOS Account public key, used for creating a new account
  - userType - User type informs if its a 'natural' or 'juridical' user for regular users and companies

-}
signUp :
    (SignUpOptionalArguments -> SignUpOptionalArguments)
    -> SignUpRequiredArguments
    -> SelectionSet decodesTo Cambiatus.Object.Session
    -> SelectionSet decodesTo RootMutation
signUp fillInOptionals requiredArgs object_ =
    let
        filledInOptionals =
            fillInOptionals { address = Absent, invitationId = Absent, kyc = Absent }

        optionalArgs =
            [ Argument.optional "address" filledInOptionals.address Cambiatus.InputObject.encodeAddressUpdateInput, Argument.optional "invitationId" filledInOptionals.invitationId Encode.string, Argument.optional "kyc" filledInOptionals.kyc Cambiatus.InputObject.encodeKycDataUpdateInput ]
                |> List.filterMap identity
    in
    Object.selectionForCompositeField "signUp" (optionalArgs ++ [ Argument.required "account" requiredArgs.account Encode.string, Argument.required "email" requiredArgs.email Encode.string, Argument.required "name" requiredArgs.name Encode.string, Argument.required "publicKey" requiredArgs.publicKey Encode.string, Argument.required "userType" requiredArgs.userType Encode.string ]) object_ identity


type alias UpsertAddressRequiredArguments =
    { input : Cambiatus.InputObject.AddressUpdateInput }


{-| [Auth required] Updates user's address if it already exists or inserts a new one if user hasn't it yet.
-}
upsertAddress :
    UpsertAddressRequiredArguments
    -> SelectionSet decodesTo Cambiatus.Object.Address
    -> SelectionSet (Maybe decodesTo) RootMutation
upsertAddress requiredArgs object_ =
    Object.selectionForCompositeField "upsertAddress" [ Argument.required "input" requiredArgs.input Cambiatus.InputObject.encodeAddressUpdateInput ] object_ (identity >> Decode.nullable)


type alias UpsertKycRequiredArguments =
    { input : Cambiatus.InputObject.KycDataUpdateInput }


{-| [Auth required] Updates user's KYC info if it already exists or inserts a new one if user hasn't it yet.
-}
upsertKyc :
    UpsertKycRequiredArguments
    -> SelectionSet decodesTo Cambiatus.Object.KycData
    -> SelectionSet (Maybe decodesTo) RootMutation
upsertKyc requiredArgs object_ =
    Object.selectionForCompositeField "upsertKyc" [ Argument.required "input" requiredArgs.input Cambiatus.InputObject.encodeKycDataUpdateInput ] object_ (identity >> Decode.nullable)


type alias UserRequiredArguments =
    { input : Cambiatus.InputObject.UserUpdateInput }


{-| [Auth required] A mutation to update a user
-}
user :
    UserRequiredArguments
    -> SelectionSet decodesTo Cambiatus.Object.User
    -> SelectionSet (Maybe decodesTo) RootMutation
user requiredArgs object_ =
    Object.selectionForCompositeField "user" [ Argument.required "input" requiredArgs.input Cambiatus.InputObject.encodeUserUpdateInput ] object_ (identity >> Decode.nullable)
