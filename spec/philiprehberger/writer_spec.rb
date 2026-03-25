# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe Philiprehberger::CsvKit::Writer do
  subject(:writer) { described_class.new(headers: %i[name age city]) }

  describe '#write' do
    it 'generates CSV from array of hashes' do
      result = writer.write([{ name: 'Alice', age: 30, city: 'Berlin' }])

      expect(result).to include('name,age,city')
      expect(result).to include('Alice,30,Berlin')
    end

    it 'generates CSV from array of arrays' do
      result = writer.write([%w[Alice 30 Berlin]])

      expect(result).to include('name,age,city')
      expect(result).to include('Alice,30,Berlin')
    end

    it 'handles multiple rows' do
      rows = [
        { name: 'Alice', age: 30, city: 'Berlin' },
        { name: 'Bob', age: 25, city: 'Vienna' }
      ]
      result = writer.write(rows)
      lines = result.strip.split("\n")

      expect(lines.length).to eq(3)
    end

    it 'handles empty rows' do
      result = writer.write([])
      lines = result.strip.split("\n")

      expect(lines.length).to eq(1)
      expect(lines.first).to eq('name,age,city')
    end

    it 'handles missing hash keys with nil' do
      result = writer.write([{ name: 'Alice' }])

      expect(result).to include('Alice,,')
    end

    it 'accepts string headers' do
      w = described_class.new(headers: %w[name age])
      result = w.write([{ name: 'Alice', age: 30 }])

      expect(result).to include('name,age')
    end

    it 'quotes values containing commas' do
      result = writer.write([{ name: 'Smith, John', age: 30, city: 'Berlin' }])

      expect(result).to include('"Smith, John"')
    end

    it 'quotes values containing double quotes' do
      result = writer.write([{ name: 'She said "hi"', age: 30, city: 'Berlin' }])

      expect(result).to include('"She said ""hi"""')
    end

    it 'quotes values containing newlines' do
      result = writer.write([{ name: "line1\nline2", age: 30, city: 'Berlin' }])

      expect(result).to include("\"line1\nline2\"")
    end

    it 'handles nil values in hash rows' do
      result = writer.write([{ name: nil, age: nil, city: nil }])
      lines = result.strip.split("\n")

      expect(lines.last).to eq(',,')
    end

    it 'handles nil values in array rows' do
      result = writer.write([[nil, nil, nil]])
      lines = result.strip.split("\n")

      expect(lines.last).to eq(',,')
    end

    it 'preserves order of headers for hash rows' do
      w = described_class.new(headers: %i[city name age])
      result = w.write([{ name: 'Alice', age: 30, city: 'Berlin' }])
      lines = result.strip.split("\n")

      expect(lines.first).to eq('city,name,age')
      expect(lines.last).to eq('Berlin,Alice,30')
    end

    it 'handles a single-column writer' do
      w = described_class.new(headers: [:id])
      result = w.write([{ id: 1 }, { id: 2 }])
      lines = result.strip.split("\n")

      expect(lines).to eq(%w[id 1 2])
    end
  end

  describe '#write_to' do
    it 'writes CSV to an IO object' do
      io = StringIO.new
      writer.write_to([{ name: 'Alice', age: 30, city: 'Berlin' }], io)
      io.rewind

      expect(io.read).to include('Alice,30,Berlin')
    end

    it 'returns the IO object' do
      io = StringIO.new
      result = writer.write_to([], io)

      expect(result).to be(io)
    end
  end
end
