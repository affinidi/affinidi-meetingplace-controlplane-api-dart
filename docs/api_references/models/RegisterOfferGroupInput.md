# RegisterOfferGroupInput
## Parameters

| Name | Type | Description | Notes |
|------------ | ------------- | ------------- | -------------|
| **offerName** | **String** | Name of the offer. | **`Required`**   |
| **offerDescription** | **String** | Describes the purpose of the connection offer. | **`Required`**   |
| **didcommMessage** | **String** | A plaintext DIDComm message containing the offer encoded in base64 format. | **`Required`**   |
| **vcard** | **String** | A vCard of the user who registered the offer encoded in base64 format. | **`Required`**   |
| **validUntil** | **String** | The validity date and time in ISO-8601 format, e.g., 2023-09-20T07:12:13  or an empty string for no expiry. |   |
| **maximumUsage** | **BigDecimal** | The maximum number of times other users can claim the offer. Set 0 for unlimited claims. |   |
| **deviceToken** | **String** | The device token for push notification when the offer is accessed.  Maximum length of 2048 characters. | **`Required`**   |
| **platformType** | **String** | Platform type for sending notification. | **`Required`**   |
| **mediatorDid** | **String** | The mediator DID use to register the offer. | **`Required`**   |
| **mediatorEndpoint** | **String** | The mediator endpoint to register the offer. | **`Required`**   |
| **mediatorWSSEndpoint** | **String** | The websocket endpoint of the mediator to register the offer. | **`Required`**   |
| **customPhrase** | **String** | A custom phrase to find and claim the offer by another user. |   |
| **isSearchable** | **Boolean** | Indicates whether the offer is searchable by other users. |   |
| **metadata** | **String** | Metadata containing additional information about the offer. |   |
| **adminReencryptionKey** | **String** | Reencryption key for the group chat admin. | **`Required`**   |
| **adminDid** | **String** | The Decentralised Identifier (DUD) of the group chat admin. | **`Required`**   |
| **adminPublicKey** | **String** | The public key information of the group chat admin. | **`Required`**   |
| **memberVCard** | **String** | A vCard of the group chat member encoded in base64 format. | **`Required`**   |

