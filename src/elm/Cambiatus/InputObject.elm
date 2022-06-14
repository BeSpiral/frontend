-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Cambiatus.InputObject exposing (..)

import Cambiatus.Enum.ContactType
import Cambiatus.Enum.Direction
import Cambiatus.Enum.TransferDirectionValue
import Cambiatus.Enum.VerificationType
import Cambiatus.Interface
import Cambiatus.Object
import Cambiatus.Scalar
import Cambiatus.ScalarCodecs
import Cambiatus.Union
import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode as Decode


buildActionsInput :
    (ActionsInputOptionalFields -> ActionsInputOptionalFields)
    -> ActionsInput
buildActionsInput fillOptionals =
    let
        optionals =
            fillOptionals
                { creator = Absent, isCompleted = Absent, validator = Absent, verificationType = Absent }
    in
    { creator = optionals.creator, isCompleted = optionals.isCompleted, validator = optionals.validator, verificationType = optionals.verificationType }


type alias ActionsInputOptionalFields =
    { creator : OptionalArgument String
    , isCompleted : OptionalArgument Bool
    , validator : OptionalArgument String
    , verificationType : OptionalArgument Cambiatus.Enum.VerificationType.VerificationType
    }


{-| Type for the ActionsInput input object.
-}
type alias ActionsInput =
    { creator : OptionalArgument String
    , isCompleted : OptionalArgument Bool
    , validator : OptionalArgument String
    , verificationType : OptionalArgument Cambiatus.Enum.VerificationType.VerificationType
    }


{-| Encode a ActionsInput into a value that can be used as an argument.
-}
encodeActionsInput : ActionsInput -> Value
encodeActionsInput input =
    Encode.maybeObject
        [ ( "creator", Encode.string |> Encode.optional input.creator ), ( "isCompleted", Encode.bool |> Encode.optional input.isCompleted ), ( "validator", Encode.string |> Encode.optional input.validator ), ( "verificationType", Encode.enum Cambiatus.Enum.VerificationType.toString |> Encode.optional input.verificationType ) ]


buildAddressUpdateInput :
    AddressUpdateInputRequiredFields
    -> (AddressUpdateInputOptionalFields -> AddressUpdateInputOptionalFields)
    -> AddressUpdateInput
buildAddressUpdateInput required fillOptionals =
    let
        optionals =
            fillOptionals
                { number = Absent }
    in
    { cityId = required.cityId, countryId = required.countryId, neighborhoodId = required.neighborhoodId, number = optionals.number, stateId = required.stateId, street = required.street, zip = required.zip }


type alias AddressUpdateInputRequiredFields =
    { cityId : Cambiatus.ScalarCodecs.Id
    , countryId : Cambiatus.ScalarCodecs.Id
    , neighborhoodId : Cambiatus.ScalarCodecs.Id
    , stateId : Cambiatus.ScalarCodecs.Id
    , street : String
    , zip : String
    }


type alias AddressUpdateInputOptionalFields =
    { number : OptionalArgument String }


{-| Type for the AddressUpdateInput input object.
-}
type alias AddressUpdateInput =
    { cityId : Cambiatus.ScalarCodecs.Id
    , countryId : Cambiatus.ScalarCodecs.Id
    , neighborhoodId : Cambiatus.ScalarCodecs.Id
    , number : OptionalArgument String
    , stateId : Cambiatus.ScalarCodecs.Id
    , street : String
    , zip : String
    }


{-| Encode a AddressUpdateInput into a value that can be used as an argument.
-}
encodeAddressUpdateInput : AddressUpdateInput -> Value
encodeAddressUpdateInput input =
    Encode.maybeObject
        [ ( "cityId", (Cambiatus.ScalarCodecs.codecs |> Cambiatus.Scalar.unwrapEncoder .codecId) input.cityId |> Just ), ( "countryId", (Cambiatus.ScalarCodecs.codecs |> Cambiatus.Scalar.unwrapEncoder .codecId) input.countryId |> Just ), ( "neighborhoodId", (Cambiatus.ScalarCodecs.codecs |> Cambiatus.Scalar.unwrapEncoder .codecId) input.neighborhoodId |> Just ), ( "number", Encode.string |> Encode.optional input.number ), ( "stateId", (Cambiatus.ScalarCodecs.codecs |> Cambiatus.Scalar.unwrapEncoder .codecId) input.stateId |> Just ), ( "street", Encode.string input.street |> Just ), ( "zip", Encode.string input.zip |> Just ) ]


buildChecksInput :
    (ChecksInputOptionalFields -> ChecksInputOptionalFields)
    -> ChecksInput
buildChecksInput fillOptionals =
    let
        optionals =
            fillOptionals
                { validator = Absent }
    in
    { validator = optionals.validator }


type alias ChecksInputOptionalFields =
    { validator : OptionalArgument String }


{-| Type for the ChecksInput input object.
-}
type alias ChecksInput =
    { validator : OptionalArgument String }


{-| Encode a ChecksInput into a value that can be used as an argument.
-}
encodeChecksInput : ChecksInput -> Value
encodeChecksInput input =
    Encode.maybeObject
        [ ( "validator", Encode.string |> Encode.optional input.validator ) ]


buildClaimsFilter :
    (ClaimsFilterOptionalFields -> ClaimsFilterOptionalFields)
    -> ClaimsFilter
buildClaimsFilter fillOptionals =
    let
        optionals =
            fillOptionals
                { claimer = Absent, direction = Absent, status = Absent }
    in
    { claimer = optionals.claimer, direction = optionals.direction, status = optionals.status }


type alias ClaimsFilterOptionalFields =
    { claimer : OptionalArgument String
    , direction : OptionalArgument Cambiatus.Enum.Direction.Direction
    , status : OptionalArgument String
    }


{-| Type for the ClaimsFilter input object.
-}
type alias ClaimsFilter =
    { claimer : OptionalArgument String
    , direction : OptionalArgument Cambiatus.Enum.Direction.Direction
    , status : OptionalArgument String
    }


{-| Encode a ClaimsFilter into a value that can be used as an argument.
-}
encodeClaimsFilter : ClaimsFilter -> Value
encodeClaimsFilter input =
    Encode.maybeObject
        [ ( "claimer", Encode.string |> Encode.optional input.claimer ), ( "direction", Encode.enum Cambiatus.Enum.Direction.toString |> Encode.optional input.direction ), ( "status", Encode.string |> Encode.optional input.status ) ]


buildCommunityUpdateInput :
    (CommunityUpdateInputOptionalFields -> CommunityUpdateInputOptionalFields)
    -> CommunityUpdateInput
buildCommunityUpdateInput fillOptionals =
    let
        optionals =
            fillOptionals
                { contacts = Absent, hasNews = Absent }
    in
    { contacts = optionals.contacts, hasNews = optionals.hasNews }


type alias CommunityUpdateInputOptionalFields =
    { contacts : OptionalArgument (List ContactInput)
    , hasNews : OptionalArgument Bool
    }


{-| Type for the CommunityUpdateInput input object.
-}
type alias CommunityUpdateInput =
    { contacts : OptionalArgument (List ContactInput)
    , hasNews : OptionalArgument Bool
    }


{-| Encode a CommunityUpdateInput into a value that can be used as an argument.
-}
encodeCommunityUpdateInput : CommunityUpdateInput -> Value
encodeCommunityUpdateInput input =
    Encode.maybeObject
        [ ( "contacts", (encodeContactInput |> Encode.list) |> Encode.optional input.contacts ), ( "hasNews", Encode.bool |> Encode.optional input.hasNews ) ]


buildContactInput :
    (ContactInputOptionalFields -> ContactInputOptionalFields)
    -> ContactInput
buildContactInput fillOptionals =
    let
        optionals =
            fillOptionals
                { externalId = Absent, label = Absent, type_ = Absent }
    in
    { externalId = optionals.externalId, label = optionals.label, type_ = optionals.type_ }


type alias ContactInputOptionalFields =
    { externalId : OptionalArgument String
    , label : OptionalArgument String
    , type_ : OptionalArgument Cambiatus.Enum.ContactType.ContactType
    }


{-| Type for the ContactInput input object.
-}
type alias ContactInput =
    { externalId : OptionalArgument String
    , label : OptionalArgument String
    , type_ : OptionalArgument Cambiatus.Enum.ContactType.ContactType
    }


{-| Encode a ContactInput into a value that can be used as an argument.
-}
encodeContactInput : ContactInput -> Value
encodeContactInput input =
    Encode.maybeObject
        [ ( "externalId", Encode.string |> Encode.optional input.externalId ), ( "label", Encode.string |> Encode.optional input.label ), ( "type", Encode.enum Cambiatus.Enum.ContactType.toString |> Encode.optional input.type_ ) ]


buildCountryInput :
    CountryInputRequiredFields
    -> CountryInput
buildCountryInput required =
    { name = required.name }


type alias CountryInputRequiredFields =
    { name : String }


{-| Type for the CountryInput input object.
-}
type alias CountryInput =
    { name : String }


{-| Encode a CountryInput into a value that can be used as an argument.
-}
encodeCountryInput : CountryInput -> Value
encodeCountryInput input =
    Encode.maybeObject
        [ ( "name", Encode.string input.name |> Just ) ]


buildKycDataUpdateInput :
    KycDataUpdateInputRequiredFields
    -> KycDataUpdateInput
buildKycDataUpdateInput required =
    { countryId = required.countryId, document = required.document, documentType = required.documentType, phone = required.phone, userType = required.userType }


type alias KycDataUpdateInputRequiredFields =
    { countryId : Cambiatus.ScalarCodecs.Id
    , document : String
    , documentType : String
    , phone : String
    , userType : String
    }


{-| Type for the KycDataUpdateInput input object.
-}
type alias KycDataUpdateInput =
    { countryId : Cambiatus.ScalarCodecs.Id
    , document : String
    , documentType : String
    , phone : String
    , userType : String
    }


{-| Encode a KycDataUpdateInput into a value that can be used as an argument.
-}
encodeKycDataUpdateInput : KycDataUpdateInput -> Value
encodeKycDataUpdateInput input =
    Encode.maybeObject
        [ ( "countryId", (Cambiatus.ScalarCodecs.codecs |> Cambiatus.Scalar.unwrapEncoder .codecId) input.countryId |> Just ), ( "document", Encode.string input.document |> Just ), ( "documentType", Encode.string input.documentType |> Just ), ( "phone", Encode.string input.phone |> Just ), ( "userType", Encode.string input.userType |> Just ) ]


buildNewCommunityInput :
    NewCommunityInputRequiredFields
    -> NewCommunityInput
buildNewCommunityInput required =
    { symbol = required.symbol }


type alias NewCommunityInputRequiredFields =
    { symbol : String }


{-| Type for the NewCommunityInput input object.
-}
type alias NewCommunityInput =
    { symbol : String }


{-| Encode a NewCommunityInput into a value that can be used as an argument.
-}
encodeNewCommunityInput : NewCommunityInput -> Value
encodeNewCommunityInput input =
    Encode.maybeObject
        [ ( "symbol", Encode.string input.symbol |> Just ) ]


buildProductsFilterInput :
    (ProductsFilterInputOptionalFields -> ProductsFilterInputOptionalFields)
    -> ProductsFilterInput
buildProductsFilterInput fillOptionals =
    let
        optionals =
            fillOptionals
                { account = Absent, categoriesIds = Absent, inStock = Absent }
    in
    { account = optionals.account, categoriesIds = optionals.categoriesIds, inStock = optionals.inStock }


type alias ProductsFilterInputOptionalFields =
    { account : OptionalArgument String
    , categoriesIds : OptionalArgument (List (Maybe Int))
    , inStock : OptionalArgument Bool
    }


{-| Type for the ProductsFilterInput input object.
-}
type alias ProductsFilterInput =
    { account : OptionalArgument String
    , categoriesIds : OptionalArgument (List (Maybe Int))
    , inStock : OptionalArgument Bool
    }


{-| Encode a ProductsFilterInput into a value that can be used as an argument.
-}
encodeProductsFilterInput : ProductsFilterInput -> Value
encodeProductsFilterInput input =
    Encode.maybeObject
        [ ( "account", Encode.string |> Encode.optional input.account ), ( "categoriesIds", (Encode.int |> Encode.maybe |> Encode.list) |> Encode.optional input.categoriesIds ), ( "inStock", Encode.bool |> Encode.optional input.inStock ) ]


buildPushSubscriptionInput :
    PushSubscriptionInputRequiredFields
    -> PushSubscriptionInput
buildPushSubscriptionInput required =
    { authKey = required.authKey, endpoint = required.endpoint, pKey = required.pKey }


type alias PushSubscriptionInputRequiredFields =
    { authKey : String
    , endpoint : String
    , pKey : String
    }


{-| Type for the PushSubscriptionInput input object.
-}
type alias PushSubscriptionInput =
    { authKey : String
    , endpoint : String
    , pKey : String
    }


{-| Encode a PushSubscriptionInput into a value that can be used as an argument.
-}
encodePushSubscriptionInput : PushSubscriptionInput -> Value
encodePushSubscriptionInput input =
    Encode.maybeObject
        [ ( "authKey", Encode.string input.authKey |> Just ), ( "endpoint", Encode.string input.endpoint |> Just ), ( "pKey", Encode.string input.pKey |> Just ) ]


buildReadNotificationInput :
    ReadNotificationInputRequiredFields
    -> ReadNotificationInput
buildReadNotificationInput required =
    { id = required.id }


type alias ReadNotificationInputRequiredFields =
    { id : Int }


{-| Type for the ReadNotificationInput input object.
-}
type alias ReadNotificationInput =
    { id : Int }


{-| Encode a ReadNotificationInput into a value that can be used as an argument.
-}
encodeReadNotificationInput : ReadNotificationInput -> Value
encodeReadNotificationInput input =
    Encode.maybeObject
        [ ( "id", Encode.int input.id |> Just ) ]


buildSubcategoryInput :
    SubcategoryInputRequiredFields
    -> SubcategoryInput
buildSubcategoryInput required =
    { id = required.id }


type alias SubcategoryInputRequiredFields =
    { id : Int }


{-| Type for the SubcategoryInput input object.
-}
type alias SubcategoryInput =
    { id : Int }


{-| Encode a SubcategoryInput into a value that can be used as an argument.
-}
encodeSubcategoryInput : SubcategoryInput -> Value
encodeSubcategoryInput input =
    Encode.maybeObject
        [ ( "id", Encode.int input.id |> Just ) ]


buildTransferDirection :
    (TransferDirectionOptionalFields -> TransferDirectionOptionalFields)
    -> TransferDirection
buildTransferDirection fillOptionals =
    let
        optionals =
            fillOptionals
                { direction = Absent, otherAccount = Absent }
    in
    { direction = optionals.direction, otherAccount = optionals.otherAccount }


type alias TransferDirectionOptionalFields =
    { direction : OptionalArgument Cambiatus.Enum.TransferDirectionValue.TransferDirectionValue
    , otherAccount : OptionalArgument String
    }


{-| Type for the TransferDirection input object.
-}
type alias TransferDirection =
    { direction : OptionalArgument Cambiatus.Enum.TransferDirectionValue.TransferDirectionValue
    , otherAccount : OptionalArgument String
    }


{-| Encode a TransferDirection into a value that can be used as an argument.
-}
encodeTransferDirection : TransferDirection -> Value
encodeTransferDirection input =
    Encode.maybeObject
        [ ( "direction", Encode.enum Cambiatus.Enum.TransferDirectionValue.toString |> Encode.optional input.direction ), ( "otherAccount", Encode.string |> Encode.optional input.otherAccount ) ]


buildTransferFilter :
    (TransferFilterOptionalFields -> TransferFilterOptionalFields)
    -> TransferFilter
buildTransferFilter fillOptionals =
    let
        optionals =
            fillOptionals
                { communityId = Absent, date = Absent, direction = Absent }
    in
    { communityId = optionals.communityId, date = optionals.date, direction = optionals.direction }


type alias TransferFilterOptionalFields =
    { communityId : OptionalArgument String
    , date : OptionalArgument Cambiatus.ScalarCodecs.Date
    , direction : OptionalArgument TransferDirection
    }


{-| Type for the TransferFilter input object.
-}
type alias TransferFilter =
    { communityId : OptionalArgument String
    , date : OptionalArgument Cambiatus.ScalarCodecs.Date
    , direction : OptionalArgument TransferDirection
    }


{-| Encode a TransferFilter into a value that can be used as an argument.
-}
encodeTransferFilter : TransferFilter -> Value
encodeTransferFilter input =
    Encode.maybeObject
        [ ( "communityId", Encode.string |> Encode.optional input.communityId ), ( "date", (Cambiatus.ScalarCodecs.codecs |> Cambiatus.Scalar.unwrapEncoder .codecDate) |> Encode.optional input.date ), ( "direction", encodeTransferDirection |> Encode.optional input.direction ) ]


buildTransferSucceedInput :
    TransferSucceedInputRequiredFields
    -> TransferSucceedInput
buildTransferSucceedInput required =
    { from = required.from, symbol = required.symbol, to = required.to }


type alias TransferSucceedInputRequiredFields =
    { from : String
    , symbol : String
    , to : String
    }


{-| Type for the TransferSucceedInput input object.
-}
type alias TransferSucceedInput =
    { from : String
    , symbol : String
    , to : String
    }


{-| Encode a TransferSucceedInput into a value that can be used as an argument.
-}
encodeTransferSucceedInput : TransferSucceedInput -> Value
encodeTransferSucceedInput input =
    Encode.maybeObject
        [ ( "from", Encode.string input.from |> Just ), ( "symbol", Encode.string input.symbol |> Just ), ( "to", Encode.string input.to |> Just ) ]


buildUnreadNotificationsSubscriptionInput :
    UnreadNotificationsSubscriptionInputRequiredFields
    -> UnreadNotificationsSubscriptionInput
buildUnreadNotificationsSubscriptionInput required =
    { account = required.account }


type alias UnreadNotificationsSubscriptionInputRequiredFields =
    { account : String }


{-| Type for the UnreadNotificationsSubscriptionInput input object.
-}
type alias UnreadNotificationsSubscriptionInput =
    { account : String }


{-| Encode a UnreadNotificationsSubscriptionInput into a value that can be used as an argument.
-}
encodeUnreadNotificationsSubscriptionInput : UnreadNotificationsSubscriptionInput -> Value
encodeUnreadNotificationsSubscriptionInput input =
    Encode.maybeObject
        [ ( "account", Encode.string input.account |> Just ) ]


buildUserUpdateInput :
    (UserUpdateInputOptionalFields -> UserUpdateInputOptionalFields)
    -> UserUpdateInput
buildUserUpdateInput fillOptionals =
    let
        optionals =
            fillOptionals
                { avatar = Absent, bio = Absent, claimNotification = Absent, contacts = Absent, digest = Absent, email = Absent, interests = Absent, location = Absent, name = Absent, transferNotification = Absent }
    in
    { avatar = optionals.avatar, bio = optionals.bio, claimNotification = optionals.claimNotification, contacts = optionals.contacts, digest = optionals.digest, email = optionals.email, interests = optionals.interests, location = optionals.location, name = optionals.name, transferNotification = optionals.transferNotification }


type alias UserUpdateInputOptionalFields =
    { avatar : OptionalArgument String
    , bio : OptionalArgument String
    , claimNotification : OptionalArgument Bool
    , contacts : OptionalArgument (List ContactInput)
    , digest : OptionalArgument Bool
    , email : OptionalArgument String
    , interests : OptionalArgument String
    , location : OptionalArgument String
    , name : OptionalArgument String
    , transferNotification : OptionalArgument Bool
    }


{-| Type for the UserUpdateInput input object.
-}
type alias UserUpdateInput =
    { avatar : OptionalArgument String
    , bio : OptionalArgument String
    , claimNotification : OptionalArgument Bool
    , contacts : OptionalArgument (List ContactInput)
    , digest : OptionalArgument Bool
    , email : OptionalArgument String
    , interests : OptionalArgument String
    , location : OptionalArgument String
    , name : OptionalArgument String
    , transferNotification : OptionalArgument Bool
    }


{-| Encode a UserUpdateInput into a value that can be used as an argument.
-}
encodeUserUpdateInput : UserUpdateInput -> Value
encodeUserUpdateInput input =
    Encode.maybeObject
        [ ( "avatar", Encode.string |> Encode.optional input.avatar ), ( "bio", Encode.string |> Encode.optional input.bio ), ( "claimNotification", Encode.bool |> Encode.optional input.claimNotification ), ( "contacts", (encodeContactInput |> Encode.list) |> Encode.optional input.contacts ), ( "digest", Encode.bool |> Encode.optional input.digest ), ( "email", Encode.string |> Encode.optional input.email ), ( "interests", Encode.string |> Encode.optional input.interests ), ( "location", Encode.string |> Encode.optional input.location ), ( "name", Encode.string |> Encode.optional input.name ), ( "transferNotification", Encode.bool |> Encode.optional input.transferNotification ) ]
