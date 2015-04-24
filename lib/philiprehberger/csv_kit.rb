# frozen_string_literal: true

require 'csv'
require_relative 'csv_kit/version'
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
    # @yield [Processor] processor to configure transforms and validations
    # @return [Array<Row>] collected rows
    def self.process(path_or_io, &block)
      processor = Processor.new(path_or_io)
      block.call(processor)
      processor.run
    end

    # Load an entire CSV into an array of symbolized hashes.
    #
    # @param path [String] file path
    # @return [Array<Hash{Symbol => String}>]
    def self.to_hashes(path)
      CSV.foreach(path, headers: true).map do |row|
        row.to_h.transform_keys(&:to_sym)
      end
    end

    # Extract specific columns from a CSV.
    #
    # @param path [String] file path
    # @param keys [Array<Symbol>] column names to extract
    # @return [Array<Hash{Symbol => String}>]
    def self.pluck(path, *keys)
      to_hashes(path).map { |h| h.slice(*keys) }
    end

    # Filter rows and return matching rows as a CSV string.
    #
    # @param path [String] file path
    # @yield [Hash{Symbol => String}] each row as a symbolized hash
    # @return [String] CSV string with headers
    def self.filter(path, &)
      rows = to_hashes(path).select(&)
      return '' if rows.empty?

      headers = rows.first.keys
      CSV.generate do |csv|
        csv << headers
        rows.each { |row| csv << headers.map { |k| row[k] } }
      end
    end
  end
end
