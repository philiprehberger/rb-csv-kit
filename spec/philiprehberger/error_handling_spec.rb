# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe 'Error handling' do
  def write_csv(content)
    file = Tempfile.new(['test', '.csv'])
    file.write(content)
    file.rewind
    file
  end

  let(:csv_content) { "name,age,city\nAlice,30,Berlin\nBob,bad,Vienna\nCarol,35,Zurich\n" }
  let(:csv_file) { write_csv(csv_content) }

  after { csv_file.close! if csv_file.respond_to?(:close!) }

  describe 'Processor#on_error' do
    it 'skips rows when handler returns :skip' do
      rows = Philiprehberger::CsvKit.process(csv_file.path) do |p|
        p.on_error { |_row, _err| :skip }
        p.transform(:age) { |v| Integer(v) }
      end

      expect(rows.length).to eq(2)
      expect(rows.map { |r| r[:name] }).to contain_exactly('Alice', 'Carol')
    end

    it 'aborts when handler returns :abort' do
      expect do
        Philiprehberger::CsvKit.process(csv_file.path) do |p|
          p.on_error { |_row, _err| :abort }
          p.transform(:age) { |v| Integer(v) }
        end
      end.to raise_error(Philiprehberger::CsvKit::Error, /Aborted/)
    end

    it 'passes row and error to the handler' do
      captured_row = nil
      captured_error = nil

      Philiprehberger::CsvKit.process(csv_file.path) do |p|
        p.on_error do |row, err|
          captured_row = row
          captured_error = err
          :skip
        end
        p.transform(:age) { |v| Integer(v) }
      end

      expect(captured_row[:name]).to eq('Bob')
      expect(captured_error).to be_a(ArgumentError)
    end

    it 'skips by default when no handler is set' do
      rows = Philiprehberger::CsvKit.process(csv_file.path) do |p|
        p.transform(:age) { |v| Integer(v) }
      end

      expect(rows.length).to eq(2)
    end
  end

  describe 'Processor#max_errors' do
    let(:many_bad_csv) do
      lines = ['name,age'] + (1..20).map { |i| "Person#{i},bad" }
      write_csv("#{lines.join("\n")}\n")
    end

    after { many_bad_csv.close! if many_bad_csv.respond_to?(:close!) }

    it 'raises after N errors are collected' do
      expect do
        Philiprehberger::CsvKit.process(many_bad_csv.path) do |p|
          p.max_errors(5)
          p.on_error { |_row, _err| :skip }
          p.transform(:age) { |v| Integer(v) }
        end
      end.to raise_error(Philiprehberger::CsvKit::Error, /Max errors \(5\) reached/)
    end

    it 'collects errors for inspection' do
      processor = Philiprehberger::CsvKit::Processor.new(many_bad_csv.path)
      processor.max_errors(3)
      processor.on_error { |_row, _err| :skip }
      processor.transform(:age) { |v| Integer(v) }

      expect { processor.run }.to raise_error(Philiprehberger::CsvKit::Error)
      expect(processor.errors.length).to eq(3)
      expect(processor.errors.first).to have_key(:row)
      expect(processor.errors.first).to have_key(:error)
    end

    it 'does not raise when errors are below limit' do
      rows = Philiprehberger::CsvKit.process(csv_file.path) do |p|
        p.max_errors(10)
        p.on_error { |_row, _err| :skip }
        p.transform(:age) { |v| Integer(v) }
      end

      expect(rows.length).to eq(2)
    end
  end
end
