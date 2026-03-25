# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe 'Callbacks and aliasing' do
  def write_csv(content)
    file = Tempfile.new(['test', '.csv'])
    file.write(content)
    file.rewind
    file
  end

  let(:csv_content) { "name,age,city\nAlice,30,Berlin\nBob,25,Vienna\n" }
  let(:csv_file) { write_csv(csv_content) }

  after { csv_file.close! if csv_file.respond_to?(:close!) }

  describe 'Processor#rename' do
    it 'renames columns during processing' do
      rows = Philiprehberger::CsvKit.process(csv_file.path) do |p|
        p.rename(:city, :location)
      end

      expect(rows.first[:location]).to eq('Berlin')
      expect(rows.first.key?(:city)).to be(false)
    end

    it 'supports multiple renames' do
      rows = Philiprehberger::CsvKit.process(csv_file.path) do |p|
        p.rename(:name, :full_name)
        p.rename(:city, :location)
      end

      expect(rows.first[:full_name]).to eq('Alice')
      expect(rows.first[:location]).to eq('Berlin')
    end

    it 'applies renames after transforms' do
      rows = Philiprehberger::CsvKit.process(csv_file.path) do |p|
        p.transform(:age, &:to_i)
        p.rename(:age, :years)
      end

      expect(rows.first[:years]).to eq(30)
      expect(rows.first.key?(:age)).to be(false)
    end
  end

  describe 'Processor#after_each' do
    it 'calls the callback after each row' do
      collected = []

      Philiprehberger::CsvKit.process(csv_file.path) do |p|
        p.after_each { |row| collected << row[:name] }
      end

      expect(collected).to eq(%w[Alice Bob])
    end

    it 'receives the fully transformed row' do
      collected = []

      Philiprehberger::CsvKit.process(csv_file.path) do |p|
        p.transform(:age, &:to_i)
        p.rename(:city, :location)
        p.after_each { |row| collected << row.to_h }
      end

      expect(collected.first).to eq(name: 'Alice', age: 30, location: 'Berlin')
    end

    it 'runs after the each callback' do
      order = []

      Philiprehberger::CsvKit.process(csv_file.path) do |p|
        p.each { |_row| order << :each }
        p.after_each { |_row| order << :after_each }
      end

      expect(order).to eq(%i[each after_each each after_each])
    end
  end

  describe 'Processor#rename with non-existent column' do
    it 'silently ignores renaming a column that does not exist' do
      rows = Philiprehberger::CsvKit.process(csv_file.path) do |p|
        p.rename(:nonexistent, :something)
      end

      expect(rows.first.key?(:something)).to be(false)
      expect(rows.first[:name]).to eq('Alice')
    end
  end

  describe 'Processor#after_each with reject' do
    it 'does not call after_each for rejected rows' do
      collected = []

      Philiprehberger::CsvKit.process(csv_file.path) do |p|
        p.reject { |row| row[:name] == 'Bob' }
        p.after_each { |row| collected << row[:name] }
      end

      expect(collected).to eq(%w[Alice])
    end
  end

  describe 'Processor#after_each with validation' do
    it 'does not call after_each for rows that fail validation' do
      collected = []

      Philiprehberger::CsvKit.process(csv_file.path) do |p|
        p.validate(:age) { |v| v.to_i >= 30 }
        p.after_each { |row| collected << row[:name] }
      end

      expect(collected).to eq(%w[Alice])
    end
  end

  describe Philiprehberger::CsvKit::Row do
    subject(:row) { described_class.new(name: 'Alice', age: '30') }

    it 'supports key?' do
      expect(row.key?(:name)).to be(true)
      expect(row.key?(:missing)).to be(false)
    end

    it 'supports delete' do
      row.delete(:age)

      expect(row.key?(:age)).to be(false)
    end
  end
end
