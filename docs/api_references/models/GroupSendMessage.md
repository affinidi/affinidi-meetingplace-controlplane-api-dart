# GroupSendMessage
## Parameters

| Name | Type | Description | Notes |
|------------ | ------------- | ------------- | -------------|
| **offerLink** | **String** | The Offer link associated with the group chat. | **`Required`**   |
| **fromDid** | **String** | The Decentralised Identifier (DID) of the message sender. | **`Required`**   |
| **groupDid** | **String** | The channel DID for the group chat. | **`Required`**   |
| **payload** | **String** | Input payload containing the message to send to the group chat. | **`Required`**   |
| **ephemeral** | **Boolean** | Indicates whether the message is ephemeral and should not be stored persistently. |   |
| **expiresTime** | **String** | The date and time of when the message expires in ISO-8601 format, e.g., 2023-09-20T07:12:13. |   |
| **notify** | **Boolean** | Indicates whether to send a notification to the group chat members using push notification. |   |
| **incSeqNo** | **Boolean** | Indicates whether to increment the sequence number of the message in the group chat. |   |

