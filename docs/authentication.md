# Authentication

Calling all API endpoints available in the Control Plane API requires an access token as part of the request header, except for endpoints responsible for authentication. 

For authenticated calls, the API expects a **Bearer Token** to be present in the `Authorization` field of the request header. To obtain an access token, it requires two authentication requests.

* `/authenticate/challenge`
* `/authenticate`

Referring to the sequence diagram below, the caller obtains an access token by completing the `/authenticate/challenge` and `/authenticate` calls. 

The caller must provide a DID to use as their primary identifier for all calls, then prove they hold the private key for this DID as part of the authentication challenge process.

After successfully obtaining the access token, include it in the request header on all subsequent calls to the Control Plane API that require authentication.

```mermaid
sequenceDiagram
    autonumber
    participant Caller
    participant API as Control Plane API

    rect rgb(107, 107, 107)
    note right of Caller: Caller sends their DID<br/>{'did': 'did:peer:...'});
    Caller->>+API: POST /authenticate/challenge
    note right of API: Generate auth challenge token  
    API-->>-Caller: Returns auth challenge token

    note right of Caller: Caller sends an encrypted DIDComm message<br/> signed with their private key, containing<br/> the auth challenge to the Control Plane API DID
    Caller->>+API: POST /authenticate
    note right of API: Validates the signature of the DIDComm message<br/>and returns the access_token, if successful
    API-->>-Caller: Return access token
    end
    note right of Caller: Caller uses the access_token<br/>as a bearer token for subsequent API calls
    Caller->>+API: example: POST /check-offer-phrase
    note right of API: Validates the bearer token
    API-->>-Caller: Returns result of the operation

```

See the example Dart code for the authentication flow [here](../test/utils/authoritzation.dart).
