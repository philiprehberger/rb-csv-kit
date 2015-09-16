# frozen_string_literal: true

module Philiprehberger
  module CsvKit
    # Mixin for per-row error handling and max-error tracking.
    module ErrorHandler
      # Configure a per-row error handler.
      #
      # @yield [Hash, StandardError] the row data and the error
      # @yieldreturn [:skip, :abort] action to take
      def on_error(&block)
        @error_handler = block
      end

      # Set a maximum number of errors before aborting.
      #
      # @param limit [Integer] max errors allowed
      # @return [self]
      def max_errors(limit)
        @max_errors = limit
        self
      end

      # Returns collected errors from the last run.
      #
      # @return [Array<Hash>] error details
      def errors
        @errors ||= []
      end

      private

      def init_error_handler
        @error_handler = nil
        @max_errors = nil
        @errors = []
      end

      def handle_row_error(row, err)
        @errors << { row: row.to_h, error: err }
        check_max_errors!
        resolve_error_action(row, err)
      end

      def check_max_errors!
        return unless @max_errors && @errors.length >= @max_errors

        raise Error, "Max errors (#{@max_errors}) reached"
      end

      def resolve_error_action(row, err)
        return :skip unless @error_handler

        @error_handler.call(row, err)
      end
    end
  end
end
