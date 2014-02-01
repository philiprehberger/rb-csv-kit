# frozen_string_literal: true

module Philiprehberger
  module CsvKit
    # Streaming CSV processor with a DSL for transforms, validations, and filtering.
    class Processor
      def initialize(path_or_io)
        @path_or_io = path_or_io
        @transforms = {}
        @validations = {}
        @reject_block = nil
        @each_block = nil
        @header_names = nil
      end

      # Override header names used for symbolized keys.
      #
      # @param names [Array<Symbol>] header names
      def headers(*names)
        @header_names = names.map(&:to_sym)
      end

      # Register a transform for a specific column.
      #
      # @param key [Symbol] column name
      # @yield [String] raw cell value
      def transform(key, &block)
        @transforms[key] = block
      end

      # Register a validation for a specific column. Rows failing validation are skipped.
      #
      # @param key [Symbol] column name
      # @yield [String] cell value
      def validate(key, &block)
        @validations[key] = block
      end

      # Register a reject predicate. Rows matching are excluded.
      #
      # @yield [Row] the row
      def reject(&block)
        @reject_block = block
      end

      # Register a callback for each processed row.
      #
      # @yield [Row] the row
      def each(&block)
        @each_block = block
      end

      # Execute the processor, streaming row by row.
      #
      # @return [Array<Row>] collected rows
      def run
        open_csv { |csv| process_rows(csv) }
      end

      private

      def process_rows(csv)
        csv.each_with_object([]) do |csv_row, results|
          row = build_row(csv_row)
          next unless valid?(row)
          next if rejected?(row)

          apply_transforms!(row)
          @each_block&.call(row)
          results << row
        end
      end

      def open_csv(&block)
        if @path_or_io.is_a?(String)
          CSV.open(@path_or_io, headers: true, &block)
        else
          csv = CSV.new(@path_or_io, headers: true)
          block.call(csv)
        end
      end

      def build_row(csv_row)
        data = csv_row.to_h
        if @header_names
          values = data.values
          mapped = @header_names.zip(values).to_h
          Row.new(mapped)
        else
          Row.new(data.transform_keys(&:to_sym))
        end
      end

      def valid?(row)
        @validations.all? { |key, blk| blk.call(row[key]) }
      end

      def rejected?(row)
        @reject_block&.call(row) || false
      end

      def apply_transforms!(row)
        @transforms.each { |key, blk| row[key] = blk.call(row[key]) }
      end
    end
  end
end
