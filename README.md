# Affinidi Meeting Place - Control Plane API for Dart

![image](README/meetingplace-banner.png)

The **Affinidi Meeting Place - Control Plane API** provides capabilities to enable the discovery of other participants to establish a connection and communicate securely. The Control Plane API enables participants to publish a connection offer that allows them to be discoverable and facilitates the creation of a secure communication channel with other participants.

The Control Plane API is built on Dart for a high-performance server, which provides optimal speed and stability for handling API requests.

> DISCLAIMER: Affinidi provides this API as a developer tool to facilitate decentralized discovery and messaging. Any personal data exchanged or stored via this tool is entirely initiated and controlled by end-users. Affinidi does not collect, access, or process such data. Implementing parties are responsible for ensuring that their applications comply with applicable privacy laws and user transparency obligations.

## Tables of Contents

- [Affinidi Meeting Place - Control Plane API for Dart](#affinidi-meeting-place---control-plane-api-for-dart)
  - [Tables of Contents](#tables-of-contents)
  - [Key Features](#key-features)
  - [Core Concepts](#core-concepts)
  - [Requirements](#requirements)
  - [Setting Up API Server](#setting-up-api-server)
    - [Environment Variables](#environment-variables)
    - [Local Setup using SSI Persistent Wallet](#local-setup-using-ssi-persistent-wallet)
      - [Run API in Development Mode](#run-api-in-development-mode)
    - [Run Control Plane API using Docker](#run-control-plane-api-using-docker)
  - [Test API Server](#test-api-server)
  - [Working with Control Plane API](#working-with-control-plane-api)
    - [Authentication](#authentication)
    - [Calling Authenticated Endpoint](#calling-authenticated-endpoint)
    - [API References](#api-references)
  - [Secret Manager](#secret-manager)
    - [Secrets List](#secrets-list)
    - [Local Secret Manager](#local-secret-manager)
    - [AWS Secret Manager](#aws-secret-manager)
  - [Push Notifications](#push-notifications)
    - [AWS SNS Configuration](#aws-sns-configuration)
  - [Support \& Feedback](#support--feedback)
    - [Reporting technical issues](#reporting-technical-issues)
  - [Contributing](#contributing)

## Key Features

- **Discovery**: Enables the discovery of other participants within the Meeting Place through published invitations, enhancing digital interactions.

- **DID Authentication**: Uses DID and DIDComm Message for secure authentication to generate an access token to call endpoints.

- **Out-of-Band Invitation**: Enable out-of-band communication to establish a connection between participants (e.g., individuals, businesses, and AI agents).

- **Device Registration and Notification:** Secure device registration ensures seamless delivery of notifications on key events, including push notifications on the user's device.

- **Group Chat**: Provides group chat functionality, including management of members and sending messages to group members.


## Core Concepts

- **Decentralised Identifier (DID)** - A globally unique identifier that enables secure interactions. The DID is the cornerstone of Self-Sovereign Identity (SSI), a concept that aims to put individuals or entities in control of their digital identities.

- **Out-Of-Band** - The protocol defined in DIDComm enables sharing a DIDComm message or invitation through a transport method other than a direct, established DIDComm channel, such as via a QR code or a URL to create a new connection.

- **Discovery** - The Control Plane API allows participants to create connection offers or invitations that other parties can claim to initiate connection requests and establish a secure communication channel.

## Requirements

- Install Dart SDK ^3.6.0
- Install Redis
- Install Docker

## Setting Up API Server

### Environment Variables

List of the environment variables required to run the Control Plane API server.

| Variable Name | Description |
|---------------|-------------|
| ENV           | Specifies the environment in which the server is running. By default, it is set to `DEV`. |
| SERVER_PORT | Specifies the port on which the server listens for incoming requests. |
| API_ENDPOINT | Defines the API endpoint (e.g., http://localhost) to receive requests from the callers. |
| CONTROL_PLANE_DID | The DID used for authentication (e.g., did:web:yourdomain.com). The caller will resolve the CONTROL_PLANE_DID to fetch the public key information and encrypt the DIDComm message containing the auth challenge string. For testing or running the server locally, use the `did:local:8080` - replace the `8080` depending on your configured SERVER_PORT. |
| STORAGE_ENDPOINT | Specifies the endpoint for the storage instance to access the stored data. Use `localhost` when running the instance locally. |
| STORAGE_PORT | Specifies the port used by the storage instance to handle requests. For example, if you use the default Redis configuration, the port will be `6379`. |
| DIDCOMM_AUTH_SECRET | Specifies path and filename containing the didcommauth secret (e.g., `secrets/didcommauth.json`) |
| HASH_SECRET | A secret value to enhance the security of hashing operations within the application. |
| DID_DOCUMENT | Specifies path and filename of the DID document parameter (e.g., `params/did_document.json`. |

Configure the following environment variables if AWS is the selected option.

| Variable Name | Description |
|---------------|-------------|
| AWS_REGION | Specifies the AWS region to access the AWS services. |
| AWS_ACCESS_KEY | Specifies the AWS access key used when accessing AWS services. |
| AWS_SECRET_KEY | Specifies the AWS secret key used when accessing AWS services. |
| AWS_SESSION_TOKEN | Specifies the AWS session token used when accessing AWS services with temporary credentials. |
|

### Local Setup using SSI Persistent Wallet

Run the Control Plane API server using the persistent wallet provided by [Affinidi SSI](https://pub.dev/packages/ssi) library.

> Execute the following commands inside the repository folder.

1. Create a copy the required files.

   Create a copy of `config.yml` from examples folder to the root of the directory.

   ```bash
   docker-compose -f dev/docker-compose.dev.yml up -d
   ```

2. Copy the application configuration file.

   ```bash
   cp examples/config/config.example.yml config.yml
   ```

3. Create a .env file to setup your environment.

   ```bash
   cp examples/env/.env.example .env
   ```

4. Create key pairs to generate JSON Web Keys (JWKs) for DIDCommAuth.

   ```bash
   mkdir -p ./keys ./params ./secrets

   openssl ecparam -name secp256k1 -genkey -noout -out ./keys/secp256k1.pem
   openssl ecparam -name prime256v1 -genkey -noout -out ./keys/p256.pem

   openssl genpkey -algorithm Ed25519 -out ./keys/ed25519.pem
   openssl pkey -in keys/ed25519.pem -pubout -out ./keys/ed25519-pub.pem
   ```

5. Run the setup script to generate JWKs from the key pairs.

   ```bash
   dart run script/setup.dart
   ```

   The script will generate the required secrets files to run the API server.

   For more info about managing secrets, go to the [Secrets List](#secrets-list) section.

6. After setting up the required keys and secrets, run the server.

   ```bash
   dart run bin/server_local.dart -e dart
   ```

Navigate to `http://localhost:3000` or whichever host and port you use in the configuration to verify if the Control Plane API is running.

**NOTE:** The persistent wallet will be empty after each restart as it uses an in-memory storage solution.

#### Run API in Development Mode

Use [nodemon](https://www.npmjs.com/package/nodemon) to apply the code changes directly while running the API server. Use the following command to install it globally on your machine.

```bash
npm install -g nodemon
```

After installing `nodemon`, run the API server using the following command.

```bash
nodemon -x "dart run bin/server_local.dart " -e dart
```

The repository provides different server_*.dart files. Depending on the implementation, Dart files ensure you run the correct server file.


### Run Control Plane API using Docker

To run the Control Plane API with Docker, follow these steps:

1. Create a copy the required files.
   Copy the example Docker Compose file to a new docker-compose.yml file:

   ```bash
   cp examples/docker/local/docker-compose.example.yml docker-compose.yml
   ```

   Create a copy of `config.yml` from examples folder to the root of the directory.

   ```bash
   cp examples/config/config.example.yml config.yml
   ``` 

2. Set environment variables in the docker file.

   - Open the newly copied docker-compose.yml file and update the necessary environment variables, such as storage, API endpoint, and [secrets](#secrets-list).
   - For more information about environment variables, refer to [environment variables section](#environment-variables).

3. Create key pairs to generate JSON Web Keys (JWKs) for DIDCommAuth.

   ```bash
   mkdir -p ./keys ./params ./secrets

   openssl ecparam -name secp256k1 -genkey -noout -out ./keys/secp256k1.pem
   openssl ecparam -name prime256v1 -genkey -noout -out ./keys/p256.pem

   openssl genpkey -algorithm Ed25519 -out ./keys/ed25519.pem
   openssl pkey -in keys/ed25519.pem -pubout -out ./keys/ed25519-pub.pem
   ```

4. Run the setup script to generate JWKs from the key pairs.

   ```bash
   dart run script/setup.dart
   ```

   The script will generate the required secrets files to run the API server.

   For more info about managing secrets, go to the [Secrets List](#secrets-list) section.

5. Start the application using docker compose build command:
   
   ```bash
   docker-compose up --build
   ```

Navigate to `http://localhost:3000` or whichever host and port you use in the configuration to verify if the Control Plane API is running.


For more examples using different environment configurations, refer to the [Docker examples](https://github.com/affinidi/affinidi-meetingplace-controlplane-api-dart/blob/main/examples/docker/) folder for additional setup variations and use cases.

## Test API Server

1. Ensure that the `.env` file is set up and properly configured.

2. Install dependencies and prepare code.

   ```bash
   dart pub get
   dart run build_runner build
   ```

3. Generate the keys when necessary. Skip if you have done this step.

   ```bash
   dart run script/setup.dart
   ```

4. Run the server if it is not yet running.

   ```bash
   dart run bin/server_local.dart
   ```

5. While the server is running, run the test script.

   ```bash
   dart test --chain-stack-traces
   ```

## Working with Control Plane API

The Control Plane API requires an access token to call the endpoints. It uses a Decentralised Identifier (DID) and a DIDComm Message to authenticate users and generate the required token.

### Authentication

The Control Plane API expects the Bearer Token to be present in the Authorization header of the request header. To obtain the token, a 2-step API request is required.

1. Make a POST `/authenticate/challenge` with your DID as the payload. 

   ```bash
   POST /v1/authenticate/challenge

   {
      "did": "did:peer:...."
   }
   ```

   The endpoint returns a challenge string response required in the subsequent request as part of a DIDComm message using the `challengeToken` property and your DID.

   ```json
   {
      "challenge": "string"
   }
   ```

   Sign the DIDComm message with the private key associated with your DID and encrypt it with the Control Plane API's public key published through its DID, proving ownership of the DID used on Step 1.

2. After building the DIDComm message with a challenge string and encoding it with base64, call the `/authenticate` endpoint to obtain the token.

   ```bash
   POST /v1/authenticate

   {
      "challenge_response": "string"
   }
   ```

   The endpoint will return the access token, including the refresh token and duration of each token.

   ```json
   {
      "access_token": "string",
      "access_expires_at": "string",
      "refresh_token": "string",
      "refresh_expires_at": "string"
   }
   ```

Use the access token in the Authorization header to call protected endpoints, such as device registration and publishing connection offers for discovery.

Refer to the [authentication flow](https://github.com/affinidi/affinidi-meetingplace-controlplane-api-dart/blob/main/docs/authentication.md) document for more details.

### Calling Authenticated Endpoint

To call the authenticated API endpoints, use the `DIDCommAuthToken` generated from the `/authenticate` using DID and DIDComm Message.

**Endpoint:** POST `/v1/check-offer-phrase`
**Header:** Auhorization: Bearer <DidCommTokenAuth>

**Request** `application/json` 

```bash
{
  "offerPhrase": "ExistingOfferPhrase"
}
```

**Response** `application/json`

```json
{
  "isInUse": true
}
```

### API References

Refer to the [list of available](https://github.com/affinidi/affinidi-meetingplace-controlplane-api-dart/blob/main/docs/api_references/) endpoints from the Control Plane API.

## Secret Manager

The Control Plane API currently supports two secret managers.

- [Local Secret Manager](#local-secret-manager)
- [AWS Secret Manager](#aws-secret-manager)

To define which secret manager to use, set the `SECRET_MANAGER` variable in the environment configuration file.

If you wish to extend the list of supported secret managers or modify the existing implementation's functionality, refer to the [`secret_manager.dart`](https://github.com/affinidi/affinidi-meetingplace-controlplane-api-dart/blob/main/lib/src/packages/secret_manager/secret_manager.dart) file. 

### Secrets List

To generate secrets automatically, run `dart run script/setup.dart`.

| Secret Name | Description |
|-------------|-------------|
| `didcommauth` | To sign and verify tokens, generate and configure the `didcommauth` secret. This secret is stored differently depending on the secret manager in use. The secret is a JSON string containing a list of private JWKs. |
| `hash_secret` | A secret value used to enhance the security of hashing operations within the application. |

### Local Secret Manager

If you're using a local secret manager, specify the path to the JSON file containing the secret value using the `DIDCOMM_AUTH_SECRET` environment variable. For example:

```bash
DIDCOMM_AUTH_SECRET=secrets/didcommauth.json
HASH_SECRET=secrets/hash-secret.txt
```

### AWS Secret Manager

If you're using AWS Secrets Manager, the `DIDCOMM_AUTH_SECRET` environment variable must contain the secret's name stored in AWS Secrets Manager, rather than the file path.

```bash
DIDCOMM_AUTH_SECRET=<MY_AWS_SECRET_NAME>
```

## Push Notifications

### AWS SNS Configuration

When using AWS SNS, correctly configure the necessary AWS credentials (e.g., `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, and `AWS_SESSION_TOKEN` *(if needed)*) in your environment.

The AWS SNS provider requires specific IAM permissions to function correctly. Ensure that your IAM policies allow the following actions: 

- `sns:Publish` 
- `sns:CreatePlatformEndpoint`.

You can also set the `pushNotificationCustomKeyProperty` property in your configuration to match the client's setup when receiving a push notification. This property specifies the key within the push notification that contains custom metadata.

```yml
deviceNotification:
  pushNotificationCustomKeyProperty: "affinidiInfo"
```

## Support & Feedback

If you face any issues or have suggestions, please don't hesitate to contact us using [this link](https://share.hsforms.com/1i-4HKZRXSsmENzXtPdIG4g8oa2v).

### Reporting technical issues

If you have a technical issue with the project's codebase, you can also create an issue directly in GitHub.

1. Ensure the bug was not already reported by searching on GitHub under
   [Issues](https://github.com/affinidi/affinidi-meetingplace-controlplane-api-dart/issues).

2. If you're unable to find an open issue addressing the problem,
   [open a new one](https://github.com/affinidi/affinidi-meetingplace-controlplane-api-dart/issues/new).
   Be sure to include a **title and a clear description**, as much relevant information as possible,
   and a **code sample** or an **executable test case** demonstrating the expected behaviour that is not occurring.


## Contributing

Want to contribute?

Head over to our [CONTRIBUTING](https://github.com/affinidi/affinidi-meetingplace-controlplane-api-dart/blob/main/CONTRIBUTING.md) guidelines.
