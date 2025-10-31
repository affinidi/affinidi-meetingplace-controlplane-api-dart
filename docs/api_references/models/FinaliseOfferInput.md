# FinaliseOfferInput
## Parameters

| Name | Type | Description | Notes |
|------------ | ------------- | ------------- | -------------|
| **mnemonic** | **String** | A unique phrase used to publish and identify the offer. | **`Required`**   |
| **did** | **String** | Channel DID to use to finalise the acceptance of an offer. | **`Required`**   |
| **offerLink** | **String** | Offer link associated with the channel. | **`Required`**   |
| **theirDid** | **String** | Decentralised Identifier (DID) of the user who accepted the offer. | **`Required`**   |
| **deviceToken** | **String** | The device token for push notification when the offer is processed.  Maximum length of 2048 characters. |   |
| **platformType** | **String** | Platform type for sending notification. |   |

