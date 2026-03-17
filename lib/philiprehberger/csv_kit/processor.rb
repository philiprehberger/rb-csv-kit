# frozen_string_literal: true

module Philiprehberger
  module CsvKit
    # Streaming CSV processor with a DSL for transforms, validations, and filtering.
    class Processor
      include ErrorHandler
      include Callbacks

      def initialize(path_or_io)
        @path_or_io = path_or_io
        @transforms = {}
        @validations = {}
        @reject_block = nil
        @each_block = nil
        @header_names = nil
        init_error_handler
        init_callbacks
      end

      # Override header names used for symbolized keys.
      def headers(*names)
        @header_names = names.map(&:to_sym)
      end

      # Register a transform for a specific column.
      def transform(key, &block)
        @transforms[key] = block
      end

      # Register a validation for a specific column.
      def validate(key, &block)
        @validations[key] = block
      end

      # Register a reject predicate.
      def reject(&block)
        @reject_block = block
      end

      # Register a callback for each processed row.
      def each(&block)
        @each_block = block
      end

      # Execute the processor, streaming row by row.
      #
      # @return [Array<Row>] collected rows
      def run
        @collected_errors = []
        open_csv { |csv| process_rows(csv) }
      end

      private

      def process_rows(csv)
        csv.each_with_object([]) do |csv_row, results|
          process_single_row(csv_row, results)
        end
      end

      def process_single_row(csv_row, results)
        row = build_row(csv_row)
        return unless valid?(row)
        return if rejected?(row)

        apply_transforms!(row)
        apply_renames!(row)
        @each_block&.call(row)
        @after_each_block&.call(row)
        results << row
      rescue StandardError => e
        handle_error_for_row(row, e, results)
      end

      def handle_error_for_row(row, err, _results)
        action = handle_row_error(row, err)
        raise Error, "Aborted: #{err.message}" if action == :abort
      end

      def open_csv(&block)
        if @path_or_io.is_a?(String)
          CSV.open(@path_or_io, headers: true, &block)
        else
          block.call(CSV.new(@path_or_io, headers: true))
        end
      end

      def build_row(csv_row)
        data = csv_row.to_h
        if @header_names
          mapped = @header_names.zip(data.values).to_h
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
