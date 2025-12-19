# GroupAddMemberInput
## Parameters

| Name | Type | Description | Notes |
|------------ | ------------- | ------------- | -------------|
| **mnemonic** | **String** | A unique phrase used to publish and identify the offer. | **`Required`**   |
| **offerLink** | **String** | The offer link | **`Required`**   |
| **groupId** | **String** | Unique identifier of the group chat to which the member will be added. | **`Required`**   |
| **memberDid** | **String** | Decentralised Identifier (DID) of the member to add to the group chat. | **`Required`**   |
| **acceptOfferAsDid** | **String** | Decentralised Identifier (DID) of when the member accepted the offer. | **`Required`**   |
| **reencryptionKey** | **String** | The reencryption key for the group chat member. | **`Required`**   |
| **publicKey** | **String** | The public key information of the group chat member. | **`Required`**   |
| **contactCard** | **String** | The ContactCard of the member to add to the group chat encoded in base64 format. | **`Required`**   |

