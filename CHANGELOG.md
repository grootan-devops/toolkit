# Changelog

All notable changes to this project are documented in this file. The format is
based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this
project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.5] - 2026-09-21

### Added

- Competing pull request used to prove promotion picks the merged candidate.

## [1.0.4] - 2026-09-21

### Fixed

- Release notes no longer inline the full Trivy report, which pushed the GitHub
  release body past its 125,000-character limit. The report stays attached as
  `trivy_scan_report.tar.gz`.

## [1.0.3] - 2026-09-21

### Fixed

- Release artifacts are attached again: the CI library's containerised jobs called
  `gh`, which is not in the toolkit image, so every provenance lookup and the
  candidate artifact download silently returned nothing.

### Added

- The image creates `$GOPATH/bin`, which `PATH` already referenced, and the smoke
  test asserts it.

## [1.0.2] - 2026-09-21

### Added

- Smoke test asserts `NODE_PATH`, which the image sets beside `NODE_HOME` but the
  test never checked.

## [1.0.1] - 2026-09-21

### Added

- Smoke test now verifies `yarnpkg`, which the image links beside `yarn` but the
  test never exercised.

### Changed

- The release pipeline promotes the image the pull request built rather than
  rebuilding it, and no longer re-runs lint, scan or the release guards.

## [1.0.0] - 2026-09-19

### Added

- Initial toolkit Docker E2E project.
