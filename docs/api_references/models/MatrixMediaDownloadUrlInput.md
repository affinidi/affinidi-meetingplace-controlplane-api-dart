# MatrixMediaDownloadUrlInput

**Type:** Object

## Properties

| Name | Type | Description | Notes |
|------|------|-------------|-------|
| **challengeResponse** | **String** | Compact JWS challenge response proving DID ownership. | [optional] |
| **homeserver** | **String** | Matrix homeserver base URL used for room-membership verification. | [optional] |
| **roomId** | **String** | Matrix room ID whose membership authorizes the media download. | [optional] |
| **mediaUri** | **String** | `mxc://` Matrix media URI to proxy through the control plane. | [optional] |
