# frozen_string_literal: true

module Philiprehberger
  module CsvKit
    # Wraps a CSV row as a hash with symbolized keys.
    class Row
      # @param data [Hash{Symbol => String}]
      def initialize(data)
        @data = data
      end

      # Access a value by symbolized key.
      #
      # @param key [Symbol] column name
      # @return [Object]
      def [](key)
        @data[key]
      end

      # Set a value by symbolized key.
      #
      # @param key [Symbol] column name
      # @param value [Object] new value
      def []=(key, value)
        @data[key] = value
      end

      # Return the row as a plain hash.
      #
      # @return [Hash{Symbol => Object}]
      def to_h
        @data.dup
      end
    end
  end
end
