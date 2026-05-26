# DidChallengeOK
## Parameters

| Name | Type | Description | Notes |
|------------ | ------------- | ------------- | -------------|
| **challenge** | **String** | A signed JWT challenge token bound to the `authenticate` purpose. Contains `jti` (unique identifier) and `purpose` claims. Valid for 60 seconds and may only be submitted once to `/v1/authenticate`. |   |

