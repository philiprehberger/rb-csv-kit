# philiprehberger-csv_kit

[![Tests](https://github.com/philiprehberger/rb-csv-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-csv-kit/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-csv_kit.svg)](https://rubygems.org/gems/philiprehberger-csv_kit)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-csv-kit)](https://github.com/philiprehberger/rb-csv-kit/commits/main)

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

### Inspect Headers

```ruby
Philiprehberger::CsvKit.headers("data.csv")
# => [:name, :age, :city]
```

### Count Rows

```ruby
Philiprehberger::CsvKit.count("data.csv")
# => 1000
```

### Streaming Row-by-Row

Iterate rows with constant memory. Returns an `Enumerator` if no block is given:

```ruby
Philiprehberger::CsvKit.each_hash("large.csv") do |row|
  puts row[:name]
end

# Or compose with Enumerator methods:
adults = Philiprehberger::CsvKit.each_hash("data.csv")
  .select { |r| r[:age].to_i >= 18 }
  .first(10)
```

### Reservoir Sampling

Return n randomly sampled rows with O(n) memory using Knuth's Algorithm R. If the file has fewer than n rows, all rows are returned:

```ruby
rows = Philiprehberger::CsvKit.sample("large.csv", 100)
# => [{name: "Alice", age: "30"}, ...]
```

### Find First Match

Return the first row that matches a predicate, streaming and stopping on the first hit:

```ruby
user = Philiprehberger::CsvKit.find("users.csv") { |row| row[:email] == "a@b.com" }
# => {email: "a@b.com", name: "Alice"} or nil
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

### Default Values for Missing Cells

Fill nil or empty-string cells with a default value before any `type` coercion runs:

```ruby
Philiprehberger::CsvKit.process("users.csv") do |p|
  p.default(:country, "US")
  p.type(:age, :integer)
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

### Write CSV String

Inverse of `to_hashes`. Serialize an array of hashes to a CSV string. Headers default to the keys of the first row:

```ruby
csv = Philiprehberger::CsvKit.to_csv([
  { name: "Alice", age: 30 },
  { name: "Bob",   age: 25 }
])
# => "name,age\nAlice,30\nBob,25\n"

# Control column order / subset with explicit headers
Philiprehberger::CsvKit.to_csv(rows, headers: [:name])
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

### Skip and Limit

```ruby
rows = Philiprehberger::CsvKit.process("data.csv") do |p|
  p.skip(10)   # skip first 10 rows
  p.limit(50)  # stop after 50 rows
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
| `CsvKit.to_hashes(path_or_io, dialect:)` | Load CSV into array of symbolized hashes |
| `CsvKit.to_csv(rows, headers:, dialect:)` | Serialize an array of hashes to a CSV string |
| `CsvKit.sample(path_or_io, n, dialect:)` | Return n randomly sampled rows using reservoir sampling (Algorithm R) |
| `CsvKit.pluck(path_or_io, *keys, dialect:)` | Extract specific columns |
| `CsvKit.filter(path_or_io, dialect:, &block)` | Filter rows, return CSV string |
| `CsvKit.find(path_or_io, dialect:, &block)` | Return the first row matching the predicate, or nil |
| `CsvKit.headers(path_or_io, dialect:)` | Return header row as array of symbols |
| `CsvKit.count(path_or_io, dialect:)` | Count data rows without loading into memory |
| `CsvKit.each_hash(path_or_io, dialect:, &block)` | Stream rows as symbolized hashes; returns Enumerator if no block |
| `CsvKit.process(path_or_io, dialect:, &block)` | Streaming DSL with transforms and validations |
| `Processor#headers(*names)` | Override header names |
| `Processor#transform(key, &block)` | Register column transform |
| `Processor#type(key, type, **opts)` | Register built-in type coercion (:integer, :float, :string, :date, :datetime) |
| `Processor#default(key, value)` | Fill nil or empty cells at `key` with `value` (runs before `type` coercion) |
| `Processor#validate(key, &block)` | Register column validation (skip invalid) |
| `Processor#skip(n)` | Skip the first N data rows |
| `Processor#limit(n)` | Stop after processing N rows |
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
| `Row#keys` | Column names as array of symbols |
| `Row#values` | Column values as array |
| `Row#size` | Number of columns |
| `Row#each { \|k, v\| }` | Iterate key-value pairs (Enumerable) |
| `Row#merge(other)` | Return new Row with merged data |
| `Row#to_h` | Convert row to plain hash |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-csv-kit)

🐛 [Report issues](https://github.com/philiprehberger/rb-csv-kit/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-csv-kit/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
