# frozen_string_literal: true

module Philiprehberger
  module CsvKit
    # Generates CSV output from arrays of hashes or arrays.
    class Writer
      # @param headers [Array<Symbol, String>] column headers
      def initialize(headers:)
        @headers = headers.map(&:to_sym)
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
    end
  end
end
