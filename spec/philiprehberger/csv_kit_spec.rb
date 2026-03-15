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
  end

  describe '.pluck' do
    it 'extracts specific columns' do
      result = described_class.pluck(csv_file.path, :name, :city)

      expect(result.length).to eq(3)
      expect(result.first).to eq(name: 'Alice', city: 'Berlin')
      expect(result.first).not_to have_key(:age)
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
  end
end
