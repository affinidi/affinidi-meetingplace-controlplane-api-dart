# AcceptOfferInput
## Parameters

| Name | Type | Description | Notes |
|------------ | ------------- | ------------- | -------------|
| **mnemonic** | **String** | A unique phrase used to publish and identify the offer. | **`Required`**   |
| **did** | **String** | Permanent channel DID of the user upon approval of the connection request. | **`Required`**   |
| **deviceToken** | **String** | The device token for push notification when the offer is processed.  Maximum length of 2048 characters. | **`Required`**   |
| **platformType** | **String** | Platform type for sending notification. | **`Required`**   |
| **contactCard** | **String** | A ContactCard containing the details of the offer encoded in base64 format. | **`Required`**   |
| **offerLink** | **String** |  | **`Required`**   |

