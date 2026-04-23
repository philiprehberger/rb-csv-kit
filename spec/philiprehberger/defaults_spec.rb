# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe 'Processor#default' do
  def write_csv(content)
    file = Tempfile.new(['test', '.csv'])
    file.write(content)
    file.rewind
    file
  end

  it 'fills a nil cell with the default value' do
    file = write_csv("name,country\nAlice,\nBob,DE\n")
    rows = Philiprehberger::CsvKit.process(file.path) do |p|
      p.default(:country, 'US')
    end

    expect(rows.first[:country]).to eq('US')
    expect(rows.last[:country]).to eq('DE')
    file.close!
  end

  it 'fills an empty-string cell with the default value' do
    file = write_csv("name,country\nAlice,\"\"\nBob,DE\n")
    rows = Philiprehberger::CsvKit.process(file.path) do |p|
      p.default(:country, 'US')
    end

    expect(rows.first[:country]).to eq('US')
    file.close!
  end

  it 'leaves a present non-empty cell untouched' do
    file = write_csv("name,country\nAlice,FR\n")
    rows = Philiprehberger::CsvKit.process(file.path) do |p|
      p.default(:country, 'US')
    end

    expect(rows.first[:country]).to eq('FR')
    file.close!
  end

  it 'chains with #type so defaults run before coercion' do
    file = write_csv("name,age\nAlice,\nBob,42\n")
    rows = Philiprehberger::CsvKit.process(file.path) do |p|
      p.default(:age, '0')
      p.type(:age, :integer)
    end

    expect(rows.first[:age]).to eq(0)
    expect(rows.last[:age]).to eq(42)
    file.close!
  end

  it 'supports multiple defaults on different keys' do
    file = write_csv("name,country,tier\nAlice,,\nBob,DE,gold\n")
    rows = Philiprehberger::CsvKit.process(file.path) do |p|
      p.default(:country, 'US')
      p.default(:tier, 'free')
    end

    expect(rows.first[:country]).to eq('US')
    expect(rows.first[:tier]).to eq('free')
    expect(rows.last[:country]).to eq('DE')
    expect(rows.last[:tier]).to eq('gold')
    file.close!
  end

  it 'returns self for chaining' do
    file = write_csv("name,country\nAlice,\n")
    Philiprehberger::CsvKit.process(file.path) do |p|
      expect(p.default(:country, 'US')).to be(p)
    end
    file.close!
  end
end
