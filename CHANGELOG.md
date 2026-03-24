# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2026-03-24

### Changed

- The library saw a complete overhaul thanks to the suggestions made by @Cinderella-Man to
  now actually providing individual strategies that mirror Litestream's backup destinations.
  All of the backup strategies can be found under the `Litestream.Strategy.*` namespace.
- This library now leans on the `0.5.*` releases from Litestream and no longer support `0.4.*`.

## [0.4.0] - 2023-06-04

### Changed

- Updated the version of `:castore` to version `1.0`

## [0.3.0] - 2022-09-23

### Changed

- Support for version 0.3.9 of Litestream
- Updated the version of `:erlexec` to version `2.0.0`

## [0.2.0] - 2022-04-18

### Added

- Support for version 0.3.8 of Litestream

### Fixed

- The error when downloading Linux versions of the binary
