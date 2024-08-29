# frozen_string_literal: true

module Philiprehberger
  module CsvKit
    # Wraps a CSV row as a hash with symbolized keys.
    class Row
      include Enumerable

      # @param data [Hash{Symbol => String}]
      def initialize(data)
        @data = data
      end

      # Iterate over key-value pairs.
      #
      # @yield [Symbol, Object] key and value
      def each(&)
        @data.each(&)
      end

      # Return column names.
      #
      # @return [Array<Symbol>]
      def keys
        @data.keys
      end

      # Return column values.
      #
      # @return [Array<Object>]
      def values
        @data.values
      end

      # Return the number of columns.
      #
      # @return [Integer]
      def size
        @data.size
      end

      # Merge another hash or Row into this row, returning a new Row.
      #
      # @param other [Hash, Row] data to merge
      # @return [Row]
      def merge(other)
        other_data = other.is_a?(Row) ? other.to_h : other
        Row.new(@data.merge(other_data))
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

      # Check if a key exists.
      #
      # @param key [Symbol] column name
      # @return [Boolean]
      def key?(key)
        @data.key?(key)
      end

      # Delete a key from the row.
      #
      # @param key [Symbol] column name
      # @return [Object, nil] removed value
      def delete(key)
        @data.delete(key)
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
