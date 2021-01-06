# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe 'Writer.stream' do
  describe '.stream' do
    it 'writes header and rows incrementally' do
      io = StringIO.new
      Philiprehberger::CsvKit::Writer.stream(io, headers: %i[name age]) do |w|
        w << { name: 'Alice', age: 30 }
        w << { name: 'Bob', age: 25 }
      end
      io.rewind

      lines = io.read.strip.split("\n")
      expect(lines[0]).to eq('name,age')
      expect(lines[1]).to eq('Alice,30')
      expect(lines[2]).to eq('Bob,25')
    end

    it 'returns the IO object' do
      io = StringIO.new
      result = Philiprehberger::CsvKit::Writer.stream(io, headers: [:id]) do |w|
        w << { id: 1 }
      end

      expect(result).to be(io)
    end

    it 'writes header even with no rows' do
      io = StringIO.new
      Philiprehberger::CsvKit::Writer.stream(io, headers: %i[a b]) { |_w| }
      io.rewind

      expect(io.read.strip).to eq('a,b')
    end

    it 'accepts array rows' do
      io = StringIO.new
      Philiprehberger::CsvKit::Writer.stream(io, headers: %i[x y]) do |w|
        w << [1, 2]
        w << [3, 4]
      end
      io.rewind

      lines = io.read.strip.split("\n")
      expect(lines[1]).to eq('1,2')
      expect(lines[2]).to eq('3,4')
    end

    it 'handles string headers' do
      io = StringIO.new
      Philiprehberger::CsvKit::Writer.stream(io, headers: %w[name age]) do |w|
        w << { name: 'Alice', age: 30 }
      end
      io.rewind

      content = io.read
      expect(content).to include('name,age')
      expect(content).not_to be_empty
    end

    it 'handles nil values in hash rows' do
      io = StringIO.new
      Philiprehberger::CsvKit::Writer.stream(io, headers: %i[a b]) do |w|
        w << { a: nil, b: nil }
      end
      io.rewind

      lines = io.read.strip.split("\n")
      expect(lines.last).to eq(',')
    end

    it 'quotes values containing commas' do
      io = StringIO.new
      Philiprehberger::CsvKit::Writer.stream(io, headers: %i[name]) do |w|
        w << { name: 'Smith, John' }
      end
      io.rewind

      expect(io.read).to include('"Smith, John"')
    end

    it '<< returns self for chaining' do
      io = StringIO.new
      Philiprehberger::CsvKit::Writer.stream(io, headers: %i[a]) do |w|
        result = w << { a: 1 }
        expect(result).to be(w)
      end
    end

    it 'writes many rows without buffering' do
      io = StringIO.new
      Philiprehberger::CsvKit::Writer.stream(io, headers: %i[id]) do |w|
        100.times { |i| w << { id: i } }
      end
      io.rewind

      lines = io.read.strip.split("\n")
      expect(lines.length).to eq(101) # 1 header + 100 rows
    end

    it 'respects dialect settings' do
      io = StringIO.new
      Philiprehberger::CsvKit::Writer.stream(io, headers: %i[name age], dialect: { delimiter: ';' }) do |w|
        w << { name: 'Alice', age: 30 }
      end
      io.rewind

      lines = io.read.strip.split("\n")
      expect(lines[0]).to eq('name;age')
      expect(lines[1]).to eq('Alice;30')
    end

    it 'respects dialect with custom line ending' do
      io = StringIO.new
      Philiprehberger::CsvKit::Writer.stream(io, headers: %i[a], dialect: :excel) do |w|
        w << { a: 1 }
      end
      io.rewind

      content = io.read
      expect(content).to include("\r\n")
    end

    it 'chains multiple << calls' do
      io = StringIO.new
      Philiprehberger::CsvKit::Writer.stream(io, headers: %i[x]) do |w|
        w << { x: 1 } << { x: 2 } << { x: 3 }
      end
      io.rewind

      lines = io.read.strip.split("\n")
      expect(lines.length).to eq(4)
    end
  end
end
