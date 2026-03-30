# philiprehberger-csv_kit

[![Tests](https://github.com/philiprehberger/rb-csv-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-csv-kit/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-csv_kit.svg)](https://rubygems.org/gems/philiprehberger-csv_kit)
[![GitHub release](https://img.shields.io/github/v/release/philiprehberger/rb-csv-kit)](https://github.com/philiprehberger/rb-csv-kit/releases)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-csv-kit)](https://github.com/philiprehberger/rb-csv-kit/commits/main)
[![License](https://img.shields.io/github/license/philiprehberger/rb-csv-kit)](LICENSE)
[![Bug Reports](https://img.shields.io/github/issues/philiprehberger/rb-csv-kit/bug)](https://github.com/philiprehberger/rb-csv-kit/issues?q=is%3Aissue+is%3Aopen+label%3Abug)
[![Feature Requests](https://img.shields.io/github/issues/philiprehberger/rb-csv-kit/enhancement)](https://github.com/philiprehberger/rb-csv-kit/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub%20Sponsors-ec6cb9)](https://github.com/sponsors/philiprehberger)

Streaming CSV processor with type coercion and validation

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-csv_kit"
```

Or install directly:

```bash
gem install philiprehberger-csv_kit
```

## Usage

```ruby
require "philiprehberger/csv_kit"

rows = Philiprehberger::CsvKit.to_hashes("data.csv")
# => [{name: "Alice", age: "30"}, ...]
```

### Pluck Columns

```ruby
names = Philiprehberger::CsvKit.pluck("data.csv", :name, :city)
# => [{name: "Alice", city: "Berlin"}, ...]
```

### Filter Rows

```ruby
csv_string = Philiprehberger::CsvKit.filter("data.csv") do |row|
  row[:age].to_i >= 30
end
```

### Streaming Processor

```ruby
rows = Philiprehberger::CsvKit.process("data.csv") do |p|
  p.transform(:age) { |v| v.to_i }
  p.validate(:age) { |v| v.to_i.positive? }
  p.reject { |row| row[:city] == "Unknown" }
  p.each { |row| puts row[:name] }
end
```

### Date/Time Type Coercions

```ruby
rows = Philiprehberger::CsvKit.process("data.csv") do |p|
  p.type(:birthday, :date)
  p.type(:created_at, :datetime, format: "%Y-%m-%dT%H:%M:%S")
end
```

### CSV Dialects

```ruby
rows = Philiprehberger::CsvKit.to_hashes("data.csv", dialect: :excel)
rows = Philiprehberger::CsvKit.process("data.csv", dialect: { delimiter: ";", quote: "'" }) do |p|
  p.transform(:age, &:to_i)
end
```

### Writing CSV

```ruby
writer = Philiprehberger::CsvKit::Writer.new(headers: [:name, :age])
csv_string = writer.write([{ name: "Alice", age: 30 }, { name: "Bob", age: 25 }])

File.open("output.csv", "w") do |f|
  writer.write_to([{ name: "Alice", age: 30 }], f)
end
```

### Streaming Writer

```ruby
File.open("output.csv", "w") do |f|
  Philiprehberger::CsvKit::Writer.stream(f, headers: [:name, :age]) do |w|
    w << { name: "Alice", age: 30 }
    w << { name: "Bob", age: 25 }
  end
end
```

### Error Recovery

```ruby
rows = Philiprehberger::CsvKit.process("data.csv") do |p|
  p.on_error { |row, err| :skip }
  p.transform(:age) { |v| Integer(v) }
end
```

### Column Aliasing

```ruby
rows = Philiprehberger::CsvKit.process("data.csv") do |p|
  p.rename(:raw_col, :clean_col)
end
```

### Delimiter Detection

```ruby
delimiter = Philiprehberger::CsvKit::Detector.detect("data.tsv")
# => "\t"
```

## API

| Method / Class | Description |
|----------------|-------------|
| `CsvKit.to_hashes(path, dialect:)` | Load CSV into array of symbolized hashes |
| `CsvKit.pluck(path, *keys, dialect:)` | Extract specific columns |
| `CsvKit.filter(path, dialect:, &block)` | Filter rows, return CSV string |
| `CsvKit.process(path_or_io, dialect:, &block)` | Streaming DSL with transforms and validations |
| `Processor#headers(*names)` | Override header names |
| `Processor#transform(key, &block)` | Register column transform |
| `Processor#type(key, type, **opts)` | Register built-in type coercion (:integer, :float, :string, :date, :datetime) |
| `Processor#validate(key, &block)` | Register column validation (skip invalid) |
| `Processor#reject(&block)` | Reject rows matching predicate |
| `Processor#each(&block)` | Callback for each processed row |
| `Processor#on_error(&block)` | Per-row error handler (return `:skip` or `:abort`) |
| `Processor#max_errors(n)` | Stop after N errors |
| `Processor#errors` | Collected errors from last run |
| `Processor#rename(from, to)` | Rename column during processing |
| `Processor#after_each(&block)` | Callback after each row is fully processed |
| `Writer.new(headers:)` | Create a CSV writer with given headers |
| `Writer#write(rows)` | Generate CSV string from rows |
| `Writer#write_to(rows, io)` | Write CSV to an IO object |
| `Writer.stream(io, headers:, dialect:)` | Stream CSV rows incrementally to an IO |
| `Dialect.new(name_or_hash)` | Create a dialect from preset or custom hash |
| `Detector.detect(path_or_io)` | Auto-detect CSV delimiter |
| `Row#[](key)` | Access value by symbol key |
| `Row#to_h` | Convert row to plain hash |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this package useful, consider giving it a star on GitHub — it helps motivate continued maintenance and development.

[![LinkedIn](https://img.shields.io/badge/Philip%20Rehberger-LinkedIn-0A66C2?logo=linkedin)](https://www.linkedin.com/in/philiprehberger)
[![More packages](https://img.shields.io/badge/more-open%20source%20packages-blue)](https://philiprehberger.com/open-source-packages)

## License

[MIT](LICENSE)
