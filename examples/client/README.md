# Client Implementation Example

Standalone example showing how to integrate with the Meeting Place Control Plane API.

## Prerequisites

- Dart SDK >=3.6.0
- Redis running locally
- Meeting Place API server running on `localhost:3000`

## Quick Start

```bash
# Install dependencies
cd examples/client
dart pub get

# Run the example (server must be running)
dart run example_native_flow.dart
```

## What It Shows

Complete connection workflow between two users (Alice and Bob):

1. **Authentication** - DIDComm challenge-response using SSI package
2. **Device Registration** - Register devices for push notifications
3. **Offer Creation** - Alice creates a connection offer with mnemonic phrase
4. **Offer Discovery** - Bob queries the offer using the mnemonic
5. **Offer Acceptance** - Bob accepts and finalizes the connection

## Key Components

### ClientHelper (`lib/client_helper.dart`)

Reusable helper class providing:
- `createDidManagerWithKeyPair()` - Generate DID and keys using SSI wallet
- `authenticate()` - DIDComm-based authentication flow
- `getDioWithAuth()` - HTTP client with Bearer token

### LocalDidResolver

Uses the project's existing `LocalDidResolver` from `lib/src/core/did_resolver/did_local_resolver.dart`:
- Handles `did:localhost` for local development
- Falls back to `UniversalDIDResolver` for standard DID methods

## Configuration

Optional: Create `.env` from template:
```bash
cp .env.example .env
```

Default configuration:
```properties
API_ENDPOINT=http://localhost:3000
CONTROL_PLANE_DID=did:localhost:3000
```

## Using in Your Project

1. Add dependency in `pubspec.yaml`:
```yaml
dependencies:
  meeting_place_control_plane_api:
    path: ../../  # Adjust path to the API project
```

2. Import and use:
```dart
import 'lib/client_helper.dart';

final helper = ClientHelper(
  apiEndpoint: 'http://localhost:3000',
  controlPlaneDid: 'did:localhost:3000',
);

// Create DID and authenticate
final (didManager, keyPair) = await helper.createDidManagerWithKeyPair();
final token = await helper.authenticate(didManager, keyPair);

// Make authenticated requests
final dio = helper.getDioWithAuth(token);
final response = await dio.post('/v1/register-offer', data: {...});
```

## Files

- `lib/client_helper.dart` - Reusable authentication helper
- `example_native_flow.dart` - Complete Alice-to-Bob workflow
- `.env.example` - Configuration template

