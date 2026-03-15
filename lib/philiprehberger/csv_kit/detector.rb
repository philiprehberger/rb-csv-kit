# frozen_string_literal: true

module Philiprehberger
  module CsvKit
    # Detects the most likely delimiter for a CSV file by sampling its first lines.
    class Detector
      DELIMITERS = [',', "\t", ';', '|'].freeze
      SAMPLE_LINES = 5

      # Detect the delimiter used in a file or IO.
      #
      # @param path_or_io [String, IO] file path or IO object
      # @return [String] the detected delimiter
      def self.detect(path_or_io)
        lines = read_sample(path_or_io)
        return ',' if lines.empty?

        DELIMITERS.min_by { |d| variance(lines, d) }
      end

      # @api private
      def self.read_sample(path_or_io)
        if path_or_io.is_a?(String)
          File.foreach(path_or_io).first(SAMPLE_LINES)
        else
          path_or_io.rewind if path_or_io.respond_to?(:rewind)
          path_or_io.each_line.first(SAMPLE_LINES)
        end
      end

      # @api private
      def self.variance(lines, delimiter)
        counts = lines.map { |l| l.count(delimiter) }
        return Float::INFINITY if counts.all?(&:zero?)

        mean = counts.sum.to_f / counts.size
        counts.sum { |c| (c - mean)**2 } / counts.size
      end

      private_class_method :read_sample, :variance
    end
  end
end
