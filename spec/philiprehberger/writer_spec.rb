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
