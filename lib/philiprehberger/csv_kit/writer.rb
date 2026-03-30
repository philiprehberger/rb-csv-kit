# frozen_string_literal: true

module Philiprehberger
  module CsvKit
    # Generates CSV output from arrays of hashes or arrays.
    class Writer
      # @param headers [Array<Symbol, String>] column headers
      def initialize(headers:)
        @headers = headers.map(&:to_sym)
      end

      # Stream CSV rows incrementally to an IO object without buffering.
      #
      # @param io [IO] writable IO object
      # @param headers [Array<Symbol, String>] column headers
      # @param dialect [Symbol, Hash, nil] CSV dialect preset or custom options
      # @yield [StreamWriter] writer that accepts rows via <<
      # @return [IO] the IO object
      def self.stream(io, headers:, dialect: nil, &block)
        writer = StreamWriter.new(io, headers: headers, dialect: dialect)
        block.call(writer)
        io
      end

      # Write rows to a CSV string.
      #
      # @param rows [Array<Hash, Array>] data rows
      # @return [String] CSV string
      def write(rows)
        generate_csv(rows, StringIO.new).string
      end

      # Write rows to an IO object.
      #
      # @param rows [Array<Hash, Array>] data rows
      # @param io [IO] writable IO
      # @return [IO] the IO object
      def write_to(rows, io)
        generate_csv(rows, io)
        io
      end

      private

      def generate_csv(rows, io)
        csv = CSV.new(io)
        csv << @headers
        rows.each { |row| csv << row_values(row) }
        csv
      end

      def row_values(row)
        return @headers.map { |h| row[h] } if row.is_a?(Hash)

        row
      end

      # Incremental writer that streams rows to an IO object one at a time.
      class StreamWriter
        # @param io [IO] writable IO object
        # @param headers [Array<Symbol, String>] column headers
        # @param dialect [Symbol, Hash, nil] CSV dialect preset or custom options
        def initialize(io, headers:, dialect: nil)
          @headers = headers.map(&:to_sym)
          csv_opts = {}
          csv_opts = Dialect.new(dialect).merge_into(csv_opts) if dialect
          @csv = CSV.new(io, **csv_opts)
          @csv << @headers
        end

        # Append a single row to the CSV output.
        #
        # @param row [Hash, Array] a single data row
        # @return [self]
        def <<(row)
          @csv << row_values(row)
          self
        end

        private

        def row_values(row)
          return @headers.map { |h| row[h] } if row.is_a?(Hash)

          row
        end
      end
    end
  end
end
