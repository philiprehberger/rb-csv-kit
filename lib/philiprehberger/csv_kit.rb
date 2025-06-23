# frozen_string_literal: true

require 'csv'
require 'date'
require 'time'
require_relative 'csv_kit/version'
require_relative 'csv_kit/dialect'
require_relative 'csv_kit/detector'
require_relative 'csv_kit/row'
require_relative 'csv_kit/error_handler'
require_relative 'csv_kit/callbacks'
require_relative 'csv_kit/processor'
require_relative 'csv_kit/writer'

module Philiprehberger
  module CsvKit
    class Error < StandardError; end

    # Streaming DSL — yields a Processor for configuration, then executes.
    #
    # @param path_or_io [String, IO] file path or IO object
    # @param dialect [Symbol, Hash, nil] CSV dialect preset or custom options
    # @yield [Processor] processor to configure transforms and validations
    # @return [Array<Row>] collected rows
    def self.process(path_or_io, dialect: nil, &block)
      processor = Processor.new(path_or_io, dialect: dialect)
      block.call(processor)
      processor.run
    end

    # Load an entire CSV into an array of symbolized hashes.
    #
    # @param path [String] file path
    # @param dialect [Symbol, Hash, nil] CSV dialect preset or custom options
    # @return [Array<Hash{Symbol => String}>]
    def self.to_hashes(path, dialect: nil)
      csv_opts = { headers: true }
      csv_opts = Dialect.new(dialect).merge_into(csv_opts) if dialect
      CSV.foreach(path, **csv_opts).map do |row|
        row.to_h.transform_keys(&:to_sym)
      end
    end

    # Extract specific columns from a CSV.
    #
    # @param path [String] file path
    # @param keys [Array<Symbol>] column names to extract
    # @param dialect [Symbol, Hash, nil] CSV dialect preset or custom options
    # @return [Array<Hash{Symbol => String}>]
    def self.pluck(path, *keys, dialect: nil)
      to_hashes(path, dialect: dialect).map { |h| h.slice(*keys) }
    end

    # Return the header row as an array of symbols.
    #
    # @param path [String] file path
    # @param dialect [Symbol, Hash, nil] CSV dialect preset or custom options
    # @return [Array<Symbol>]
    def self.headers(path, dialect: nil)
      csv_opts = {}
      csv_opts = Dialect.new(dialect).merge_into(csv_opts) if dialect
      CSV.open(path, **csv_opts) do |csv|
        row = csv.shift
        return [] unless row

        row.map(&:to_sym)
      end
    end

    # Count data rows without loading them all into memory.
    #
    # @param path [String] file path
    # @param dialect [Symbol, Hash, nil] CSV dialect preset or custom options
    # @return [Integer]
    def self.count(path, dialect: nil)
      csv_opts = { headers: true }
      csv_opts = Dialect.new(dialect).merge_into(csv_opts) if dialect
      n = 0
      CSV.foreach(path, **csv_opts) { |_| n += 1 }
      n
    end

    # Stream rows one at a time as symbolized hashes with constant memory.
    # Returns an Enumerator if no block is given.
    #
    # @param path [String] file path
    # @param dialect [Symbol, Hash, nil] CSV dialect preset or custom options
    # @yield [Hash{Symbol => String}] each row
    # @return [Enumerator, nil]
    def self.each_hash(path, dialect: nil, &block)
      csv_opts = { headers: true }
      csv_opts = Dialect.new(dialect).merge_into(csv_opts) if dialect

      enum = Enumerator.new do |yielder|
        CSV.foreach(path, **csv_opts) do |row|
          yielder.yield(row.to_h.transform_keys(&:to_sym))
        end
      end

      block ? enum.each(&block) : enum
    end

    # Return n randomly sampled rows using reservoir sampling (Algorithm R).
    # Memory usage is O(n) regardless of file size.
    # If the file has fewer than n rows, all rows are returned.
    #
    # @param path_or_io [String, IO] file path or IO object
    # @param n [Integer] number of rows to sample
    # @param dialect [Symbol, Hash, nil] CSV dialect preset or custom options
    # @return [Array<Hash{Symbol => String}>]
    def self.sample(path_or_io, n, dialect: nil)
      csv_opts = { headers: true }
      csv_opts = Dialect.new(dialect).merge_into(csv_opts) if dialect

      reservoir = []
      index = 0

      iterate = lambda do |row|
        hash = row.to_h.transform_keys(&:to_sym)
        if index < n
          reservoir << hash
        else
          j = rand(index + 1)
          reservoir[j] = hash if j < n
        end
        index += 1
      end

      if path_or_io.is_a?(String)
        CSV.foreach(path_or_io, **csv_opts, &iterate)
      else
        CSV.new(path_or_io, **csv_opts).each(&iterate)
      end

      reservoir
    end

    # Find the first row matching a predicate, streaming (stops as soon as a match is found).
    #
    # @param path [String] file path
    # @param dialect [Symbol, Hash, nil] CSV dialect preset or custom options
    # @yield [Hash{Symbol => String}] each row as a symbolized hash
    # @return [Hash{Symbol => String}, nil] the first matching row or nil
    def self.find(path, dialect: nil, &block)
      csv_opts = { headers: true }
      csv_opts = Dialect.new(dialect).merge_into(csv_opts) if dialect
      CSV.foreach(path, **csv_opts) do |row|
        hash = row.to_h.transform_keys(&:to_sym)
        return hash if block.call(hash)
      end
      nil
    end

    # Filter rows and return matching rows as a CSV string.
    #
    # @param path [String] file path
    # @param dialect [Symbol, Hash, nil] CSV dialect preset or custom options
    # @yield [Hash{Symbol => String}] each row as a symbolized hash
    # @return [String] CSV string with headers
    def self.filter(path, dialect: nil, &)
      rows = to_hashes(path, dialect: dialect).select(&)
      return '' if rows.empty?

      headers = rows.first.keys
      CSV.generate do |csv|
        csv << headers
        rows.each { |row| csv << headers.map { |k| row[k] } }
      end
    end
  end
end
