# philiprehberger-csv_kit

[![Tests](https://github.com/philiprehberger/rb-csv-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-csv-kit/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-csv_kit.svg)](https://rubygems.org/gems/philiprehberger-csv_kit)

Streaming CSV processor with type coercion and validation.

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem 'philiprehberger-csv_kit'
```

Then run:

```bash
bundle install
```

Or install directly:

```bash
gem install philiprehberger-csv_kit
```

## Usage

```ruby
require 'philiprehberger/csv_kit'
```

### Quick Load

```ruby
rows = Philiprehberger::CsvKit.to_hashes('data.csv')
# => [{name: "Alice", age: "30"}, ...]
```

### Pluck Columns

```ruby
names = Philiprehberger::CsvKit.pluck('data.csv', :name, :city)
# => [{name: "Alice", city: "Berlin"}, ...]
```

### Filter Rows

```ruby
csv_string = Philiprehberger::CsvKit.filter('data.csv') do |row|
  row[:age].to_i >= 30
end
```

### Streaming Processor

```ruby
rows = Philiprehberger::CsvKit.process('data.csv') do |p|
  p.transform(:age) { |v| v.to_i }
  p.validate(:age) { |v| v.to_i.positive? }
  p.reject { |row| row[:city] == 'Unknown' }
  p.each { |row| puts row[:name] }
end
```

### Delimiter Detection

```ruby
delimiter = Philiprehberger::CsvKit::Detector.detect('data.tsv')
# => "\t"
```

## API

| Method / Class | Description |
|----------------|-------------|
| `CsvKit.to_hashes(path)` | Load CSV into array of symbolized hashes |
| `CsvKit.pluck(path, *keys)` | Extract specific columns |
| `CsvKit.filter(path, &block)` | Filter rows, return CSV string |
| `CsvKit.process(path_or_io, &block)` | Streaming DSL with transforms and validations |
| `Processor#headers(*names)` | Override header names |
| `Processor#transform(key, &block)` | Register column transform |
| `Processor#validate(key, &block)` | Register column validation (skip invalid) |
| `Processor#reject(&block)` | Reject rows matching predicate |
| `Processor#each(&block)` | Callback for each processed row |
| `Detector.detect(path_or_io)` | Auto-detect CSV delimiter |
| `Row#[](key)` | Access value by symbol key |
| `Row#to_h` | Convert row to plain hash |

## Development

```bash
bundle install
bundle exec rspec      # Run tests
bundle exec rubocop    # Check code style
```

## License

MIT
