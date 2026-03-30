# frozen_string_literal: true

module Philiprehberger
  module CsvKit
    # Predefined and custom CSV dialects for controlling parsing and writing behavior.
    class Dialect
      PRESETS = {
        excel: { col_sep: ',', row_sep: "\r\n", strip: true },
        excel_tab: { col_sep: "\t" },
        unix: { col_sep: ',', row_sep: "\n" }
      }.freeze

      OPTION_MAP = {
        delimiter: :col_sep,
        quote: :quote_char,
        line_ending: :row_sep
      }.freeze

      attr_reader :options

      # Build a Dialect from a preset name or a custom options hash.
      #
      # @param name_or_hash [Symbol, Hash] preset name (:excel, :excel_tab, :unix) or custom hash
      # @return [Dialect]
      def initialize(name_or_hash)
        @options = resolve(name_or_hash)
      end

      # Merge dialect options into a base CSV options hash.
      #
      # @param base [Hash] base CSV options
      # @return [Hash] merged options
      def merge_into(base)
        base.merge(@options)
      end

      private

      def resolve(name_or_hash)
        case name_or_hash
        when Symbol
          preset = PRESETS[name_or_hash]
          raise ArgumentError, "Unknown dialect: #{name_or_hash}" unless preset

          preset.dup
        when Hash
          normalize_hash(name_or_hash)
        else
          raise ArgumentError, "Dialect must be a Symbol or Hash, got #{name_or_hash.class}"
        end
      end

      def normalize_hash(hash)
        hash.each_with_object({}) do |(key, value), opts|
          csv_key = OPTION_MAP.fetch(key, key)
          opts[csv_key] = value
        end
      end
    end
  end
end
