# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe Philiprehberger::CsvKit::Dialect do
  describe '.new' do
    it 'resolves the :excel preset' do
      dialect = described_class.new(:excel)

      expect(dialect.options[:col_sep]).to eq(',')
      expect(dialect.options[:row_sep]).to eq("\r\n")
      expect(dialect.options[:strip]).to be(true)
    end

    it 'resolves the :excel_tab preset' do
      dialect = described_class.new(:excel_tab)

      expect(dialect.options[:col_sep]).to eq("\t")
    end

    it 'resolves the :unix preset' do
      dialect = described_class.new(:unix)

      expect(dialect.options[:col_sep]).to eq(',')
      expect(dialect.options[:row_sep]).to eq("\n")
    end

    it 'raises ArgumentError for unknown preset' do
      expect { described_class.new(:unknown) }.to raise_error(ArgumentError, /Unknown dialect/)
    end

    it 'accepts a custom hash with delimiter' do
      dialect = described_class.new(delimiter: ';')

      expect(dialect.options[:col_sep]).to eq(';')
    end

    it 'accepts a custom hash with quote character' do
      dialect = described_class.new(quote: "'")

      expect(dialect.options[:quote_char]).to eq("'")
    end

    it 'accepts a custom hash with line_ending' do
      dialect = described_class.new(line_ending: "\r\n")

      expect(dialect.options[:row_sep]).to eq("\r\n")
    end

    it 'accepts a custom hash with multiple options' do
      dialect = described_class.new(delimiter: ';', quote: "'", line_ending: "\n")

      expect(dialect.options[:col_sep]).to eq(';')
      expect(dialect.options[:quote_char]).to eq("'")
      expect(dialect.options[:row_sep]).to eq("\n")
    end

    it 'passes through unknown keys as-is' do
      dialect = described_class.new(col_sep: '|')

      expect(dialect.options[:col_sep]).to eq('|')
    end

    it 'raises ArgumentError for invalid type' do
      expect { described_class.new(42) }.to raise_error(ArgumentError, /Symbol or Hash/)
    end
  end

  describe '#merge_into' do
    it 'merges dialect options into a base hash' do
      dialect = described_class.new(:excel)
      result = dialect.merge_into(headers: true)

      expect(result[:headers]).to be(true)
      expect(result[:col_sep]).to eq(',')
      expect(result[:row_sep]).to eq("\r\n")
    end

    it 'dialect options override base options' do
      dialect = described_class.new(delimiter: ';')
      result = dialect.merge_into(col_sep: ',')

      expect(result[:col_sep]).to eq(';')
    end
  end
end

RSpec.describe 'Dialect integration' do
  def write_csv(content)
    file = Tempfile.new(['test', '.csv'])
    file.write(content)
    file.rewind
    file
  end

  describe 'CsvKit.to_hashes with dialect' do
    it 'parses semicolon-delimited CSV with custom dialect' do
      file = write_csv("name;age;city\nAlice;30;Berlin\n")
      result = Philiprehberger::CsvKit.to_hashes(file.path, dialect: { delimiter: ';' })

      expect(result.first).to eq(name: 'Alice', age: '30', city: 'Berlin')
      file.close!
    end

    it 'parses tab-delimited CSV with excel_tab dialect' do
      file = write_csv("name\tage\nAlice\t30\n")
      result = Philiprehberger::CsvKit.to_hashes(file.path, dialect: :excel_tab)

      expect(result.first).to eq(name: 'Alice', age: '30')
      file.close!
    end
  end

  describe 'CsvKit.pluck with dialect' do
    it 'plucks columns from semicolon-delimited CSV' do
      file = write_csv("name;age;city\nAlice;30;Berlin\n")
      result = Philiprehberger::CsvKit.pluck(file.path, :name, dialect: { delimiter: ';' })

      expect(result.first).to eq(name: 'Alice')
      file.close!
    end
  end

  describe 'CsvKit.filter with dialect' do
    it 'filters rows from semicolon-delimited CSV' do
      file = write_csv("name;age\nAlice;30\nBob;25\n")
      result = Philiprehberger::CsvKit.filter(file.path, dialect: { delimiter: ';' }) do |row|
        row[:age].to_i >= 30
      end

      expect(result).to include('Alice')
      expect(result).not_to include('Bob')
      file.close!
    end
  end

  describe 'CsvKit.process with dialect' do
    it 'processes semicolon-delimited CSV' do
      file = write_csv("name;age\nAlice;30\nBob;25\n")
      rows = Philiprehberger::CsvKit.process(file.path, dialect: { delimiter: ';' }) do |p|
        p.transform(:age, &:to_i)
      end

      expect(rows.first[:age]).to eq(30)
      expect(rows.last[:age]).to eq(25)
      file.close!
    end

    it 'processes with unix dialect' do
      file = write_csv("name,age\nAlice,30\n")
      rows = Philiprehberger::CsvKit.process(file.path, dialect: :unix) do |p|
        p.transform(:age, &:to_i)
      end

      expect(rows.first[:age]).to eq(30)
      file.close!
    end

    it 'processes with custom quote character' do
      file = write_csv("name;age\n'Alice';30\n")
      rows = Philiprehberger::CsvKit.process(file.path, dialect: { delimiter: ';', quote: "'" }) do |p|
        p.transform(:age, &:to_i)
      end

      expect(rows.first[:name]).to eq('Alice')
      file.close!
    end
  end
end
