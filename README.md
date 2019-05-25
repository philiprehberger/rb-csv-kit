# philiprehberger-csv_kit

[![Tests](https://github.com/philiprehberger/rb-csv-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-csv-kit/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-csv_kit.svg)](https://rubygems.org/gems/philiprehberger-csv_kit)
[![License](https://img.shields.io/github/license/philiprehberger/rb-csv-kit)](LICENSE)
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

### Writing CSV

```ruby
writer = Philiprehberger::CsvKit::Writer.new(headers: [:name, :age])
csv_string = writer.write([{ name: "Alice", age: 30 }, { name: "Bob", age: 25 }])

# Write to a file
File.open('output.csv', 'w') do |f|
  writer.write_to([{ name: "Alice", age: 30 }], f)
end
```

### Error Recovery

```ruby
rows = Philiprehberger::CsvKit.process('data.csv') do |p|
  p.on_error { |row, err| :skip }  # or :abort
  p.transform(:age) { |v| Integer(v) }
end
```

### Max Errors

```ruby
processor = Philiprehberger::CsvKit::Processor.new('data.csv')
processor.max_errors(10)
processor.on_error { |row, err| :skip }
processor.transform(:age) { |v| Integer(v) }

begin
  processor.run
rescue Philiprehberger::CsvKit::Error
  puts processor.errors.length  # collected errors
end
```

### Column Aliasing

```ruby
rows = Philiprehberger::CsvKit.process('data.csv') do |p|
  p.rename(:raw_col, :clean_col)
end
```

### Row Callbacks

```ruby
rows = Philiprehberger::CsvKit.process('data.csv') do |p|
  p.after_each { |row| puts row.to_h }
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
| `Processor#on_error(&block)` | Per-row error handler (return `:skip` or `:abort`) |
| `Processor#max_errors(n)` | Stop after N errors |
| `Processor#errors` | Collected errors from last run |
| `Processor#rename(from, to)` | Rename column during processing |
| `Processor#after_each(&block)` | Callback after each row is fully processed |
| `Writer.new(headers:)` | Create a CSV writer with given headers |
| `Writer#write(rows)` | Generate CSV string from rows |
| `Writer#write_to(rows, io)` | Write CSV to an IO object |
| `Detector.detect(path_or_io)` | Auto-detect CSV delimiter |
| `Row#[](key)` | Access value by symbol key |
| `Row#to_h` | Convert row to plain hash |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

[MIT](LICENSE)
