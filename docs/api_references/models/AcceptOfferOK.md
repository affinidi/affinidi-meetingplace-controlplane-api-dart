# AcceptOfferOK
## Parameters

| Name | Type | Description | Notes |
|------------ | ------------- | ------------- | -------------|
| **status** | **String** |  |   |
| **message** | **String** |  |   |
| **didcommMessage** | **String** |  | **`Required`**   |
| **offerLink** | **String** |  | **`Required`**   |
| **name** | **String** |  | **`Required`**   |
| **description** | **String** |  | **`Required`**   |
| **validUntil** | **String** | validity date and time in ISO-8601 format, e.g. 2023-09-20T07:12:13 |   |
| **maximumUsage** | **BigDecimal** |  |   |
| **vcard** | **String** | A vCard containing the details of the offer encoded in base64 format. | **`Required`**   |
| **mediatorDid** | **String** | The mediator DID use to register the offer. | **`Required`**   |
| **mediatorEndpoint** | **String** | The mediator endpoint to register the offer. | **`Required`**   |
| **mediatorWSSEndpoint** | **String** | The websocket endpoint of the mediator to register the offer. | **`Required`**   |

