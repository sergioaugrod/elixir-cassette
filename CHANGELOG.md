# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [1.2.5] - 2016-06-14
### Fixed
- Allows users with empty types

## [1.2.4] - 2016-06-09
### Fixed
- Fixes issues with environment variables when compiling the default cassette client

## [1.2.3] - 2016-06-09
### Fixed
 - Fixes issues with custom modules and environment variable configuration

## [1.2.2] - 2016-05-30
### Fixed
- Fixed a compile warning when using `Cassette.Support` macro with a custom config

## [1.2.1] - 2016-06-30
### Fixed
- Fixed issues reported by `credo`

## Changed
- Make `Cassette.Support` servers by `Application`s too

## [1.2.0] - 2016-05-25
### Added
- Macros on `Cassette.Support` now generate `start`, `start/2`
- Macros on `Cassette.Suport.child_spec/0` provide child spec for supervisors

## [1.1.0] - 2016-04-12
### Added
- support for the `cas:type` on `cas:attributes` (defaults to empty)

## [1.0.0] - 2016-01-06

### Added
- initial release with ticket generation, cache and validation
