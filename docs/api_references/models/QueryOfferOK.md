# QueryOfferOK
## Parameters

| Name | Type | Description | Notes |
|------------ | ------------- | ------------- | -------------|
| **status** | **String** |  | **`Required`**   |
| **message** | **String** |  |   |
| **offerLink** | **String** |  | **`Required`**   |
| **name** | **String** |  | **`Required`**   |
| **description** | **String** |  | **`Required`**   |
| **validUntil** | **String** | validity date and time in ISO-8601 format, e.g. 2023-09-20T07:12:13 |   |
| **contactCard** | **String** | A ContactCard containing the details of the offer encoded in base64 format. | **`Required`**   |
| **contactAttributes** | **BigDecimal** | A bitfield of contact attributes | **`Required`**   |
| **offerType** | **BigDecimal** | Offer type information |   |
| **mediatorDid** | **String** | The mediator DID use to register the offer. | **`Required`**   |
| **mediatorEndpoint** | **String** | The mediator endpoint to register the offer. | **`Required`**   |
| **mediatorWSSEndpoint** | **String** | The websocket endpoint of the mediator to register the offer. | **`Required`**   |
| **didcommMessage** | **String** | The didcomm message connected to this offer | **`Required`**   |
| **maximumUsage** | **BigDecimal** | maximum number of times this offer can be claimed, or 0 for unlimited |   |
| **groupId** | **String** |  |   |
| **groupDid** | **String** |  |   |

