# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.8.0] - 2026-04-17

### Added
- `CsvKit.to_csv(rows, headers:, dialect:)` — serialize an array of hashes to a CSV string; inverse of `to_hashes`
- `to_hashes`, `pluck`, `headers`, `count`, `each_hash`, `find`, and `filter` now accept an IO object in addition to a file path

## [0.7.0] - 2026-04-16

### Added
- `CsvKit.sample(path, n, dialect:)` — return n randomly sampled rows as symbolized hashes using reservoir sampling (Algorithm R); O(n) memory regardless of file size; returns all rows if file has fewer than n rows

## [0.6.0] - 2026-04-15

### Added
- `CsvKit.find(path, &block)` — return the first row matching a predicate, stopping as soon as a match is found

## [0.5.0] - 2026-04-09

### Added
- `CsvKit.each_hash(path, dialect:)` for streaming row-by-row iteration with constant memory; returns Enumerator if no block given
- `Row` now includes `Enumerable` with `keys`, `values`, `size`, `each`, and `merge` methods

## [0.4.0] - 2026-04-09

### Added
- `CsvKit.headers(path, dialect:)` to inspect header row without loading data
- `CsvKit.count(path, dialect:)` to count data rows without loading into memory
- `Processor#skip(n)` to skip the first N data rows
- `Processor#limit(n)` to stop after processing N rows

## [0.3.1] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.3.0] - 2026-03-29

### Added

- CSV dialect support with predefined presets (`:excel`, `:excel_tab`, `:unix`) and custom dialects
- Date/time type coercions via `Processor#type` — built-in `:date` and `:datetime` types with optional format strings
- Streaming writer via `Writer.stream(io, headers:) { |w| w << row }` for incremental CSV output
- Dialect integration into `process()`, `to_hashes()`, `pluck()`, and `filter()` methods

## [0.2.6] - 2026-03-26

### Changed

- Add Sponsor badge and fix License link format in README

## [0.2.5] - 2026-03-24

### Changed
- Expand test coverage to 60+ examples covering edge cases and error paths

## [0.2.4] - 2026-03-24

### Fixed
- Align README one-liner with gemspec summary

## [0.2.3] - 2026-03-24

### Fixed
- Standardize README code examples to use double-quote require statements
- Remove inline comments from Development section to match template

## [0.2.2] - 2026-03-18

### Changed
- Revert gemspec to single-quoted strings per RuboCop default configuration

## [0.2.1] - 2026-03-18

### Changed
- Fix RuboCop Style/StringLiterals violations in gemspec

## [0.2.0] - 2026-03-17

### Added
- CSV writing via `Writer` class — generate CSV from arrays/hashes, write to string or IO
- Configurable per-row error handling with `on_error` — return `:skip` or `:abort`
- Max error tracking with `max_errors(n)` — stop processing after N errors
- Column aliasing with `rename(:from, :to)` — rename columns during processing
- Row callbacks with `after_each` — hook after each row is fully transformed

## [0.1.2] - 2026-03-16

### Changed
- Add License badge to README
- Add bug_tracker_uri to gemspec

## [0.1.0] - 2026-03-15

### Added
- Initial release
- Streaming CSV processing with constant memory
- Auto-detect delimiter
- Type coercion and row validation
- Quick load and filtering convenience methods

[Unreleased]: https://github.com/philiprehberger/rb-csv-kit/compare/v0.8.0...HEAD
[0.8.0]: https://github.com/philiprehberger/rb-csv-kit/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/philiprehberger/rb-csv-kit/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/philiprehberger/rb-csv-kit/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/philiprehberger/rb-csv-kit/releases/tag/v0.5.0
[0.4.0]: https://github.com/philiprehberger/rb-csv-kit/releases/tag/v0.4.0
[0.3.1]: https://github.com/philiprehberger/rb-csv-kit/releases/tag/v0.3.1
[0.3.0]: https://github.com/philiprehberger/rb-csv-kit/releases/tag/v0.3.0
[0.2.6]: https://github.com/philiprehberger/rb-csv-kit/releases/tag/v0.2.6
[0.2.5]: https://github.com/philiprehberger/rb-csv-kit/releases/tag/v0.2.5
[0.2.4]: https://github.com/philiprehberger/rb-csv-kit/releases/tag/v0.2.4
[0.2.3]: https://github.com/philiprehberger/rb-csv-kit/releases/tag/v0.2.3
[0.2.2]: https://github.com/philiprehberger/rb-csv-kit/releases/tag/v0.2.2
[0.2.1]: https://github.com/philiprehberger/rb-csv-kit/releases/tag/v0.2.1
[0.2.0]: https://github.com/philiprehberger/rb-csv-kit/releases/tag/v0.2.0
[0.1.2]: https://github.com/philiprehberger/rb-csv-kit/releases/tag/v0.1.2
[0.1.0]: https://github.com/philiprehberger/rb-csv-kit/releases/tag/v0.1.0
