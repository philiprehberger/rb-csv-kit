# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe 'Date/Time type coercions' do
  def write_csv(content)
    file = Tempfile.new(['test', '.csv'])
    file.write(content)
    file.rewind
    file
  end

  describe 'Processor#type with :date' do
    it 'parses a date column using Date.parse' do
      file = write_csv("name,birthday\nAlice,2000-01-15\n")
      rows = Philiprehberger::CsvKit.process(file.path) do |p|
        p.type(:birthday, :date)
      end

      expect(rows.first[:birthday]).to eq(Date.new(2000, 1, 15))
      file.close!
    end

    it 'parses a date column with a custom format' do
      file = write_csv("name,birthday\nAlice,15/01/2000\n")
      rows = Philiprehberger::CsvKit.process(file.path) do |p|
        p.type(:birthday, :date, format: '%d/%m/%Y')
      end

      expect(rows.first[:birthday]).to eq(Date.new(2000, 1, 15))
      file.close!
    end

    it 'raises an error for invalid date format' do
      file = write_csv("name,birthday\nAlice,not-a-date\n")
      rows = Philiprehberger::CsvKit.process(file.path) do |p|
        p.on_error { |_row, _err| :skip }
        p.type(:birthday, :date)
      end

      expect(rows).to be_empty
      file.close!
    end

    it 'parses multiple date columns' do
      file = write_csv("start,end\n2025-01-01,2025-12-31\n")
      rows = Philiprehberger::CsvKit.process(file.path) do |p|
        p.type(:start, :date)
        p.type(:end, :date)
      end

      expect(rows.first[:start]).to eq(Date.new(2025, 1, 1))
      expect(rows.first[:end]).to eq(Date.new(2025, 12, 31))
      file.close!
    end

    it 'parses dates in various formats with Date.parse' do
      file = write_csv("d\n\"Jan 15, 2000\"\n")
      rows = Philiprehberger::CsvKit.process(file.path) do |p|
        p.type(:d, :date)
      end

      expect(rows.first[:d]).to eq(Date.new(2000, 1, 15))
      file.close!
    end
  end

  describe 'Processor#type with :datetime' do
    it 'parses a datetime column using Time.parse' do
      file = write_csv("name,created_at\nAlice,2025-03-29T10:30:00\n")
      rows = Philiprehberger::CsvKit.process(file.path) do |p|
        p.type(:created_at, :datetime)
      end

      expect(rows.first[:created_at]).to be_a(Time)
      expect(rows.first[:created_at].year).to eq(2025)
      expect(rows.first[:created_at].month).to eq(3)
      expect(rows.first[:created_at].day).to eq(29)
      expect(rows.first[:created_at].hour).to eq(10)
      expect(rows.first[:created_at].min).to eq(30)
      file.close!
    end

    it 'parses a datetime column with a custom format' do
      file = write_csv("name,ts\nAlice,29/03/2025 10:30:00\n")
      rows = Philiprehberger::CsvKit.process(file.path) do |p|
        p.type(:ts, :datetime, format: '%d/%m/%Y %H:%M:%S')
      end

      expect(rows.first[:ts]).to be_a(Time)
      expect(rows.first[:ts].year).to eq(2025)
      expect(rows.first[:ts].day).to eq(29)
      file.close!
    end

    it 'raises an error for invalid datetime' do
      file = write_csv("name,ts\nAlice,not-a-time\n")
      rows = Philiprehberger::CsvKit.process(file.path) do |p|
        p.on_error { |_row, _err| :skip }
        p.type(:ts, :datetime)
      end

      expect(rows).to be_empty
      file.close!
    end

    it 'parses ISO 8601 datetime strings' do
      file = write_csv("ts\n2025-03-29T10:30:00\n")
      rows = Philiprehberger::CsvKit.process(file.path) do |p|
        p.type(:ts, :datetime, format: '%Y-%m-%dT%H:%M:%S')
      end

      expect(rows.first[:ts].hour).to eq(10)
      expect(rows.first[:ts].min).to eq(30)
      expect(rows.first[:ts].sec).to eq(0)
      file.close!
    end
  end

  describe 'Processor#type with other types' do
    it 'coerces :integer type' do
      file = write_csv("name,age\nAlice,30\n")
      rows = Philiprehberger::CsvKit.process(file.path) do |p|
        p.type(:age, :integer)
      end

      expect(rows.first[:age]).to eq(30)
      file.close!
    end

    it 'coerces :float type' do
      file = write_csv("name,score\nAlice,9.5\n")
      rows = Philiprehberger::CsvKit.process(file.path) do |p|
        p.type(:score, :float)
      end

      expect(rows.first[:score]).to eq(9.5)
      file.close!
    end

    it 'coerces :string type' do
      file = write_csv("name,val\nAlice,123\n")
      rows = Philiprehberger::CsvKit.process(file.path) do |p|
        p.type(:val, :string)
      end

      expect(rows.first[:val]).to eq('123')
      file.close!
    end

    it 'raises ArgumentError for unknown type' do
      file = write_csv("name\nAlice\n")
      expect do
        Philiprehberger::CsvKit.process(file.path) do |p|
          p.type(:name, :unknown_type)
        end
      end.to raise_error(ArgumentError, /Unknown type/)
      file.close!
    end
  end

  describe 'type coercions combined with other DSL features' do
    it 'works with rename' do
      file = write_csv("name,birthday\nAlice,2000-01-15\n")
      rows = Philiprehberger::CsvKit.process(file.path) do |p|
        p.type(:birthday, :date)
        p.rename(:birthday, :dob)
      end

      expect(rows.first[:dob]).to eq(Date.new(2000, 1, 15))
      expect(rows.first.key?(:birthday)).to be(false)
      file.close!
    end

    it 'works with validation' do
      file = write_csv("name,age\nAlice,30\nBob,25\n")
      rows = Philiprehberger::CsvKit.process(file.path) do |p|
        p.type(:age, :integer)
        p.validate(:age) { |v| v.to_i >= 30 }
      end

      expect(rows.length).to eq(1)
      expect(rows.first[:name]).to eq('Alice')
      file.close!
    end

    it 'works with error handling' do
      file = write_csv("name,age\nAlice,30\nBob,bad\nCarol,35\n")
      errors = []
      rows = Philiprehberger::CsvKit.process(file.path) do |p|
        p.on_error do |_row, err|
          errors << err
          :skip
        end
        p.type(:age, :integer)
      end

      expect(rows.length).to eq(2)
      expect(errors.length).to eq(1)
      file.close!
    end
  end
end
