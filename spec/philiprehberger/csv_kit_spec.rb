# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe Philiprehberger::CsvKit do
  it 'has a version number' do
    expect(Philiprehberger::CsvKit::VERSION).not_to be_nil
  end

  def write_csv(content)
    file = Tempfile.new(['test', '.csv'])
    file.write(content)
    file.rewind
    file
  end

  let(:csv_content) do
    "name,age,city\nAlice,30,Berlin\nBob,25,Vienna\nCarol,35,Zurich\n"
  end

  let(:csv_file) { write_csv(csv_content) }

  after { csv_file.close! if csv_file.respond_to?(:close!) }

  describe '.to_hashes' do
    it 'loads CSV to array of symbolized hashes' do
      result = described_class.to_hashes(csv_file.path)

      expect(result.length).to eq(3)
      expect(result.first).to eq(name: 'Alice', age: '30', city: 'Berlin')
    end

    it 'returns an empty array for a header-only CSV' do
      file = write_csv("name,age,city\n")
      result = described_class.to_hashes(file.path)

      expect(result).to eq([])
      file.close!
    end

    it 'preserves values with special characters' do
      file = write_csv("name,note\n\"O'Brien\",\"hello, world\"\n")
      result = described_class.to_hashes(file.path)

      expect(result.first[:name]).to eq("O'Brien")
      expect(result.first[:note]).to eq('hello, world')
      file.close!
    end

    it 'handles columns with spaces by symbolizing them' do
      file = write_csv("first name,last name\nAlice,Smith\n")
      result = described_class.to_hashes(file.path)

      expect(result.first[:'first name']).to eq('Alice')
      file.close!
    end

    it 'handles quoted fields containing newlines' do
      file = write_csv("name,bio\nAlice,\"line1\nline2\"\n")
      result = described_class.to_hashes(file.path)

      expect(result.first[:bio]).to eq("line1\nline2")
      file.close!
    end

    it 'handles rows with trailing empty values' do
      file = write_csv("a,b,c\n1,,\n")
      result = described_class.to_hashes(file.path)

      expect(result.first[:b]).to be_nil
      expect(result.first[:c]).to be_nil
      file.close!
    end

    it 'handles a single-column CSV' do
      file = write_csv("id\n1\n2\n3\n")
      result = described_class.to_hashes(file.path)

      expect(result.length).to eq(3)
      expect(result.first).to eq(id: '1')
      file.close!
    end
  end

  describe '.pluck' do
    it 'extracts specific columns' do
      result = described_class.pluck(csv_file.path, :name, :city)

      expect(result.length).to eq(3)
      expect(result.first).to eq(name: 'Alice', city: 'Berlin')
      expect(result.first).not_to have_key(:age)
    end

    it 'returns empty hashes when plucking non-existent columns' do
      result = described_class.pluck(csv_file.path, :nonexistent)

      expect(result.length).to eq(3)
      expect(result.first).to eq({})
    end

    it 'returns a single-key hash when plucking one column' do
      result = described_class.pluck(csv_file.path, :name)

      expect(result.first).to eq(name: 'Alice')
      expect(result.first.keys.length).to eq(1)
    end

    it 'returns empty array when plucking from header-only CSV' do
      file = write_csv("name,age\n")
      result = described_class.pluck(file.path, :name)

      expect(result).to eq([])
      file.close!
    end

    it 'plucks a mix of existing and non-existing columns' do
      result = described_class.pluck(csv_file.path, :name, :nonexistent)

      expect(result.first).to eq(name: 'Alice')
    end
  end

  describe '.filter' do
    it 'returns filtered rows as CSV string' do
      result = described_class.filter(csv_file.path) { |row| row[:age].to_i >= 30 }

      expect(result).to include('Alice')
      expect(result).to include('Carol')
      expect(result).not_to include('Bob')
    end

    it 'returns empty string when no rows match' do
      result = described_class.filter(csv_file.path) { |row| row[:age].to_i > 100 }

      expect(result).to eq('')
    end

    it 'includes headers in the filtered output' do
      result = described_class.filter(csv_file.path) { |row| row[:name] == 'Alice' }

      lines = result.strip.split("\n")
      expect(lines.first).to include('name')
      expect(lines.first).to include('age')
      expect(lines.first).to include('city')
    end

    it 'returns all rows when every row matches' do
      result = described_class.filter(csv_file.path) { |_row| true }

      lines = result.strip.split("\n")
      expect(lines.length).to eq(4) # 1 header + 3 data rows
    end

    it 'returns empty string for header-only CSV' do
      file = write_csv("name,age\n")
      result = described_class.filter(file.path) { |_row| true }

      expect(result).to eq('')
      file.close!
    end

    it 'preserves all columns in filtered output' do
      result = described_class.filter(csv_file.path) { |row| row[:name] == 'Alice' }
      lines = result.strip.split("\n")

      expect(lines.last).to include('Alice')
      expect(lines.last).to include('30')
      expect(lines.last).to include('Berlin')
    end
  end

  describe '.process' do
    it 'applies transforms to rows' do
      rows = described_class.process(csv_file.path) do |p|
        p.transform(:age, &:to_i)
        p.each { |_row| } # no-op
      end

      expect(rows.first[:age]).to eq(30)
      expect(rows.last[:age]).to eq(35)
    end

    it 'skips rows failing validation' do
      rows = described_class.process(csv_file.path) do |p|
        p.validate(:age) { |v| v.to_i >= 30 }
      end

      expect(rows.length).to eq(2)
      names = rows.map { |r| r[:name] }
      expect(names).to contain_exactly('Alice', 'Carol')
    end

    it 'rejects rows matching reject predicate' do
      rows = described_class.process(csv_file.path) do |p|
        p.reject { |row| row[:city] == 'Vienna' }
      end

      expect(rows.length).to eq(2)
      names = rows.map { |r| r[:name] }
      expect(names).not_to include('Bob')
    end

    it 'works with StringIO' do
      io = StringIO.new(csv_content)
      rows = described_class.process(io) do |p|
        p.transform(:name, &:upcase)
      end

      expect(rows.first[:name]).to eq('ALICE')
    end

    it 'returns an empty array when CSV has only headers' do
      file = write_csv("name,age,city\n")
      rows = described_class.process(file.path) do |p|
        p.transform(:age, &:to_i)
      end

      expect(rows).to eq([])
      file.close!
    end

    it 'applies custom header names' do
      io = StringIO.new(csv_content)
      rows = described_class.process(io) do |p|
        p.headers(:full_name, :years, :location)
      end

      expect(rows.first[:full_name]).to eq('Alice')
      expect(rows.first[:years]).to eq('30')
      expect(rows.first[:location]).to eq('Berlin')
    end

    it 'combines transform, reject, and validation together' do
      rows = described_class.process(csv_file.path) do |p|
        p.transform(:age, &:to_i)
        p.validate(:age) { |v| v.to_i >= 25 }
        p.reject { |row| row[:city] == 'Zurich' }
      end

      expect(rows.length).to eq(2)
      names = rows.map { |r| r[:name] }
      expect(names).to contain_exactly('Alice', 'Bob')
    end

    it 'collects all rows when no transforms or filters are applied' do
      rows = described_class.process(csv_file.path) { |_p| }

      expect(rows.length).to eq(3)
    end

    it 'applies multiple transforms to different columns' do
      rows = described_class.process(csv_file.path) do |p|
        p.transform(:name, &:downcase)
        p.transform(:age, &:to_i)
        p.transform(:city, &:upcase)
      end

      expect(rows.first[:name]).to eq('alice')
      expect(rows.first[:age]).to eq(30)
      expect(rows.first[:city]).to eq('BERLIN')
    end

    it 'handles CSV with quoted commas in fields' do
      file = write_csv("name,note\n\"Smith, John\",\"hello\"\n")
      rows = described_class.process(file.path) { |_p| }

      expect(rows.first[:name]).to eq('Smith, John')
      file.close!
    end

    it 'transform on a nil column value passes nil to the block' do
      file = write_csv("name,age\nAlice,\n")
      rows = described_class.process(file.path) do |p|
        p.transform(:age) { |v| v.nil? ? 0 : v.to_i }
      end

      expect(rows.first[:age]).to eq(0)
      file.close!
    end

    it 'validation on a nil column value receives nil' do
      file = write_csv("name,age\nAlice,\nBob,25\n")
      rows = described_class.process(file.path) do |p|
        p.validate(:age) { |v| !v.nil? }
      end

      expect(rows.length).to eq(1)
      expect(rows.first[:name]).to eq('Bob')
      file.close!
    end

    it 'multiple validations must all pass for a row to be included' do
      rows = described_class.process(csv_file.path) do |p|
        p.validate(:age) { |v| v.to_i >= 25 }
        p.validate(:city) { |v| v != 'Vienna' }
      end

      expect(rows.length).to eq(2)
      names = rows.map { |r| r[:name] }
      expect(names).to contain_exactly('Alice', 'Carol')
    end

    it 'each callback receives each row in order' do
      collected = []
      described_class.process(csv_file.path) do |p|
        p.each { |row| collected << row[:name] }
      end

      expect(collected).to eq(%w[Alice Bob Carol])
    end

    it 'reject removes all rows when predicate always returns true' do
      rows = described_class.process(csv_file.path) do |p|
        p.reject { |_row| true }
      end

      expect(rows).to eq([])
    end

    it 'processes a large number of rows from StringIO' do
      lines = (1..100).map { |i| "Person#{i},#{i},City#{i}" }
      io = StringIO.new("name,age,city\n#{lines.join("\n")}\n")
      rows = described_class.process(io) do |p|
        p.transform(:age, &:to_i)
      end

      expect(rows.length).to eq(100)
      expect(rows.last[:age]).to eq(100)
    end
  end

  describe Philiprehberger::CsvKit::Detector do
    it 'identifies comma-separated data' do
      io = StringIO.new("a,b,c\n1,2,3\n4,5,6\n")
      result = Philiprehberger::CsvKit::Detector.detect(io)

      expect(result).to eq(',')
    end

    it 'identifies tab-separated data' do
      io = StringIO.new("a\tb\tc\n1\t2\t3\n4\t5\t6\n")
      result = Philiprehberger::CsvKit::Detector.detect(io)

      expect(result).to eq("\t")
    end

    it 'identifies semicolon-separated data' do
      io = StringIO.new("a;b;c\n1;2;3\n4;5;6\n")
      result = Philiprehberger::CsvKit::Detector.detect(io)

      expect(result).to eq(';')
    end

    it 'identifies pipe-separated data' do
      io = StringIO.new("a|b|c\n1|2|3\n4|5|6\n")
      result = Philiprehberger::CsvKit::Detector.detect(io)

      expect(result).to eq('|')
    end

    it 'defaults to comma for empty input' do
      io = StringIO.new('')
      result = Philiprehberger::CsvKit::Detector.detect(io)

      expect(result).to eq(',')
    end

    it 'defaults to comma for a single-line without delimiters' do
      io = StringIO.new("hello\n")
      result = Philiprehberger::CsvKit::Detector.detect(io)

      expect(result).to eq(',')
    end

    it 'detects delimiter from a file path' do
      file = write_csv("a;b;c\n1;2;3\n4;5;6\n")
      result = Philiprehberger::CsvKit::Detector.detect(file.path)

      expect(result).to eq(';')
      file.close!
    end

    it 'picks the delimiter with lowest variance when multiple are present' do
      io = StringIO.new("a,b;c\n1,2;3\n4,5;6\n")
      result = Philiprehberger::CsvKit::Detector.detect(io)

      expect([',', ';']).to include(result)
    end

    it 'handles a single line of data' do
      io = StringIO.new("a\tb\tc\n")
      result = Philiprehberger::CsvKit::Detector.detect(io)

      expect(result).to eq("\t")
    end

    it 'handles IO that does not respond to rewind' do
      io = StringIO.new("a|b|c\n1|2|3\n")
      allow(io).to receive(:respond_to?).and_call_original
      allow(io).to receive(:respond_to?).with(:rewind).and_return(false)
      result = Philiprehberger::CsvKit::Detector.detect(io)

      expect(result).to eq('|')
    end
  end

  describe Philiprehberger::CsvKit::Row do
    subject(:row) { described_class.new(name: 'Alice', age: '30') }

    it 'supports [] access' do
      expect(row[:name]).to eq('Alice')
    end

    it 'supports []= assignment' do
      row[:age] = 30
      expect(row[:age]).to eq(30)
    end

    it 'converts to hash' do
      expect(row.to_h).to eq(name: 'Alice', age: '30')
    end

    it 'returns nil for missing keys' do
      expect(row[:nonexistent]).to be_nil
    end

    it 'returns a duplicate hash from to_h so mutations do not affect the row' do
      hash = row.to_h
      hash[:name] = 'Modified'

      expect(row[:name]).to eq('Alice')
    end

    it 'returns the deleted value from delete' do
      result = row.delete(:age)

      expect(result).to eq('30')
    end

    it 'returns nil when deleting a non-existent key' do
      result = row.delete(:missing)

      expect(result).to be_nil
    end

    it 'supports overwriting an existing key' do
      row[:name] = 'Bob'

      expect(row[:name]).to eq('Bob')
    end

    it 'supports adding a new key' do
      row[:email] = 'alice@example.com'

      expect(row[:email]).to eq('alice@example.com')
      expect(row.key?(:email)).to be(true)
    end

    it 'works with empty data' do
      empty_row = described_class.new({})

      expect(empty_row.to_h).to eq({})
      expect(empty_row[:anything]).to be_nil
    end

    it 'key? returns false after delete' do
      row.delete(:name)

      expect(row.key?(:name)).to be(false)
    end
  end

  describe '.headers' do
    it 'returns header symbols without loading data rows' do
      result = described_class.headers(csv_file.path)
      expect(result).to eq(%i[name age city])
    end

    it 'returns empty array for an empty file' do
      file = write_csv('')
      result = described_class.headers(file.path)
      expect(result).to eq([])
      file.close!
    end

    it 'returns headers for header-only file' do
      file = write_csv("name,age\n")
      result = described_class.headers(file.path)
      expect(result).to eq(%i[name age])
      file.close!
    end
  end

  describe '.count' do
    it 'counts data rows' do
      expect(described_class.count(csv_file.path)).to eq(3)
    end

    it 'returns 0 for header-only file' do
      file = write_csv("name,age\n")
      expect(described_class.count(file.path)).to eq(0)
      file.close!
    end

    it 'returns 0 for empty file' do
      file = write_csv('')
      expect(described_class.count(file.path)).to eq(0)
      file.close!
    end
  end

  describe 'Processor#skip and #limit' do
    it 'skips the first N rows' do
      rows = described_class.process(csv_file.path) do |p|
        p.skip(1)
      end
      expect(rows.map { |r| r[:name] }).to eq(%w[Bob Carol])
    end

    it 'limits to N rows' do
      rows = described_class.process(csv_file.path) do |p|
        p.limit(2)
      end
      expect(rows.map { |r| r[:name] }).to eq(%w[Alice Bob])
    end

    it 'combines skip and limit' do
      rows = described_class.process(csv_file.path) do |p|
        p.skip(1)
        p.limit(1)
      end
      expect(rows.map { |r| r[:name] }).to eq(%w[Bob])
    end

    it 'returns empty when skip exceeds row count' do
      rows = described_class.process(csv_file.path) do |p|
        p.skip(100)
      end
      expect(rows).to be_empty
    end

    it 'returns all rows when limit exceeds row count' do
      rows = described_class.process(csv_file.path) do |p|
        p.limit(100)
      end
      expect(rows.length).to eq(3)
    end
  end

  describe '.each_hash' do
    it 'yields each row as a symbolized hash' do
      collected = []
      described_class.each_hash(csv_file.path) { |row| collected << row }
      expect(collected.length).to eq(3)
      expect(collected.first).to eq({ name: 'Alice', age: '30', city: 'Berlin' })
    end

    it 'returns an Enumerator when no block given' do
      enum = described_class.each_hash(csv_file.path)
      expect(enum).to be_a(Enumerator)
      expect(enum.first).to eq({ name: 'Alice', age: '30', city: 'Berlin' })
    end

    it 'composes with Enumerator methods' do
      names = described_class.each_hash(csv_file.path).map { |r| r[:name] }
      expect(names).to eq(%w[Alice Bob Carol])
    end

    it 'supports dialect option' do
      tsv = write_csv("name\tage\nAlice\t30\n")
      rows = described_class.each_hash(tsv.path, dialect: { delimiter: "\t" }).to_a
      expect(rows.first[:name]).to eq('Alice')
    ensure
      tsv&.close!
    end
  end

  describe Philiprehberger::CsvKit::Row do
    let(:row) { described_class.new(name: 'Alice', age: '30') }

    describe '#keys' do
      it 'returns column names' do
        expect(row.keys).to eq(%i[name age])
      end
    end

    describe '#values' do
      it 'returns column values' do
        expect(row.values).to eq(%w[Alice 30])
      end
    end

    describe '#size' do
      it 'returns number of columns' do
        expect(row.size).to eq(2)
      end
    end

    describe '#each' do
      it 'iterates over key-value pairs' do
        pairs = row.map { |k, v| [k, v] }
        expect(pairs).to eq([[:name, 'Alice'], [:age, '30']])
      end
    end

    describe '#merge' do
      it 'returns a new Row with merged data' do
        merged = row.merge(city: 'Berlin')
        expect(merged[:city]).to eq('Berlin')
        expect(merged[:name]).to eq('Alice')
      end

      it 'does not mutate the original' do
        row.merge(city: 'Berlin')
        expect(row.key?(:city)).to be false
      end

      it 'accepts another Row' do
        other = described_class.new(city: 'Berlin')
        merged = row.merge(other)
        expect(merged[:city]).to eq('Berlin')
      end
    end

    describe 'Enumerable' do
      it 'supports map' do
        result = row.map { |k, _v| k }
        expect(result).to eq(%i[name age])
      end
    end
  end
end
