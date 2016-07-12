# Changelog

## 0.2.2

- Revert gemspec to single-quoted strings per RuboCop default configuration

## 0.2.1

- Fix RuboCop Style/StringLiterals violations in gemspec

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-03-17

### Added
- CSV writing via `Writer` class — generate CSV from arrays/hashes, write to string or IO
- Configurable per-row error handling with `on_error` — return `:skip` or `:abort`
- Max error tracking with `max_errors(n)` — stop processing after N errors
- Column aliasing with `rename(:from, :to)` — rename columns during processing
- Row callbacks with `after_each` — hook after each row is fully transformed

## [0.1.2]

- Add License badge to README
- Add bug_tracker_uri to gemspec

## [Unreleased]

## [0.1.0] - 2026-03-15

### Added
- Initial release
- Streaming CSV processing with constant memory
- Auto-detect delimiter
- Type coercion and row validation
- Quick load and filtering convenience methods
