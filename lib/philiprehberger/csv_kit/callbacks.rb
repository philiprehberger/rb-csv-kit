# frozen_string_literal: true

module Philiprehberger
  module CsvKit
    # Mixin for column aliasing and row callbacks.
    module Callbacks
      # Register a callback to run after each row is processed.
      #
      # @yield [Row] the processed row
      def after_each(&block)
        @after_each_block = block
      end

      # Rename a column during processing.
      #
      # @param from [Symbol] original column name
      # @param to [Symbol] new column name
      def rename(from, to)
        @renames[from.to_sym] = to.to_sym
      end

      private

      def init_callbacks
        @after_each_block = nil
        @renames = {}
      end

      def apply_renames!(row)
        @renames.each do |from, to|
          next unless row.key?(from)

          row[to] = row[from]
          row.delete(from)
        end
      end
    end
  end
end
