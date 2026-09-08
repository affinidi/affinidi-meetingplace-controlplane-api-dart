# Change Log

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-09-08

### Changed

- Graduate to a stable release.

## [0.5.0] - 2026-09-08

### Removed

- Remove group DID (#53)

## [0.4.2] - 2026-09-07

### Security

- Address 5 security findings (#52)

## [0.4.1] - 2026-09-02

### Fixed

- Proof clock skew tolerance (#51)

## [0.4.0] - 2026-09-02

### Removed

- Remove DIDComm group messaging (#49)

## [0.3.0] - 2026-07-24

### Added

- Add optional `memberDid` filter to group-notify (#50)

## [0.2.1] - 2026-06-24

### Fixed

- Add 5-second clock skew tolerance to DID document proof validation (#47)

## [0.2.0] - 2026-06-22

### Added

- Add Matrix auth & DID document hosting; enforce challenge replay protection

## [0.1.14] - 2026-06-02

### Fixed

- Make NoneProvider endpoints deterministic per device (#39)

## [0.1.13] - 2026-03-06

### Fixed

- Return 422 when claim limit is exceeded in accept-offer endpoint (#32)

## [0.1.12] - 2026-03-05

### Added

- Add endpoint to deregister offer as admin (#17)
- Add AWS DynamoDB storage adapter (#14)

### Changed

- Replace vCard by contactCard; improve DIDComm protocol (#16)
- Use DID in QR code only; set JWT `iss`/`aud` to the API endpoint (#8)

### Fixed

- Retry platform endpoint creation on error (#30)
- Ensure all date-time values are converted to and stored in UTC (#28)
- Update query / claim count only if maximum is set (#27)
- Make device notification title configurable per env (#25)
- Update publish offer with score (#24)
- Update openapi, simplify result (#22)
- Add update-offers-vrc-count endpoint (#20)
- Await notify call to handle exception (#12)
- Handle push notification provider errors gracefully (#11)
- Add policy statement to key policy for cleanup (#10)
- Support different service endpoint variations on DID documents (#9)
- Return 422 for expired offers; refactor AWS ARN usage to SNS provider
