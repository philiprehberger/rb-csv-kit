# frozen_string_literal: true

module Philiprehberger
  module CsvKit
    # Streaming CSV processor with a DSL for transforms, validations, and filtering.
    class Processor
      include ErrorHandler
      include Callbacks

      TYPE_COERCIONS = {
        integer: ->(v, _opts) { Integer(v) },
        float: ->(v, _opts) { Float(v) },
        string: ->(v, _opts) { v.to_s },
        date: lambda { |v, opts|
          if opts[:format]
            Date.strptime(v, opts[:format])
          else
            Date.parse(v)
          end
        },
        datetime: lambda { |v, opts|
          if opts[:format]
            Time.strptime(v, opts[:format])
          else
            Time.parse(v)
          end
        }
      }.freeze

      def initialize(path_or_io, dialect: nil)
        @path_or_io = path_or_io
        @dialect = dialect ? Dialect.new(dialect) : nil
        @transforms = {}
        @defaults = {}
        @validations = {}
        @reject_block = nil
        @each_block = nil
        @header_names = nil
        @skip_count = nil
        @limit_count = nil
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

      # Register a built-in type coercion for a column.
      #
      # @param key [Symbol] column name
      # @param type_name [Symbol] one of :integer, :float, :string, :date, :datetime
      # @param opts [Hash] additional options (e.g. format: '%Y-%m-%d')
      def type(key, type_name, **opts)
        coercion = TYPE_COERCIONS[type_name]
        raise ArgumentError, "Unknown type: #{type_name}" unless coercion

        @transforms[key] = ->(v) { coercion.call(v, opts) }
      end

      # Register a default value for a column.
      #
      # Cells where the value is `nil` or an empty string are replaced with
      # the provided default during transform. Defaults run BEFORE `type`
      # coercions and `transform` blocks, so callers can default a missing
      # cell to a string and then coerce it (e.g. default to "0" then cast
      # to :integer).
      #
      # @param key [Symbol] column name
      # @param value [Object] value to use when the cell is nil or empty
      # @return [self]
      def default(key, value)
        @defaults[key] = value
        self
      end

      # Register a validation for a specific column.
      def validate(key, &block)
        @validations[key] = block
      end

      # Skip the first N data rows during processing.
      #
      # @param n [Integer] number of rows to skip
      # @return [void]
      def skip(n)
        @skip_count = n
      end

      # Stop after processing N rows.
      #
      # @param n [Integer] maximum rows to collect
      # @return [void]
      def limit(n)
        @limit_count = n
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
        skipped = 0
        csv.each_with_object([]) do |csv_row, results|
          if @skip_count && skipped < @skip_count
            skipped += 1
            next
          end
          break results if @limit_count && results.length >= @limit_count

          process_single_row(csv_row, results)
        end
      end

      def process_single_row(csv_row, results)
        row = build_row(csv_row)
        return unless valid?(row)
        return if rejected?(row)

        apply_defaults!(row)
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
        csv_opts = { headers: true }
        csv_opts = @dialect.merge_into(csv_opts) if @dialect

        if @path_or_io.is_a?(String)
          CSV.open(@path_or_io, **csv_opts, &block)
        else
          block.call(CSV.new(@path_or_io, **csv_opts))
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

      def apply_defaults!(row)
        @defaults.each do |key, value|
          current = row[key]
          row[key] = value if current.nil? || current.to_s.empty?
        end
      end

      def apply_transforms!(row)
        @transforms.each { |key, blk| row[key] = blk.call(row[key]) }
      end
    end
  end
end
