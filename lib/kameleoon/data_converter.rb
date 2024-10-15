# frozen_string_literal: true

require 'kameleoon/types'
require 'kameleoon/data/conversion'
require 'kameleoon/data/custom_data'

module Kameleoon
  # DataConverter is used to convert data from OpenFeature to Kameleoon.
  class DataConverter
    class << self
      def conversion_methods
        # Dictionary which contains conversion methods by keys
        @conversion_methods ||= {
          Kameleoon::Types::Data::Type::CONVERSION => method(:make_conversion),
          Kameleoon::Types::Data::Type::CUSTOM_DATA => method(:make_custom_data)
        }
      end

      # ToKameleoon converts EvaluationContext to Kameleoon SDK data types.
      def to_kameleoon(context)
        return [] if context.nil?

        data = []
        context.fields.each do |key, value|
          method = conversion_methods[key]
          next if method.nil? || value.nil?
          values = value.is_a?(Array) ? value : [value]
          values.each do |val|
            data << method.call(val)
          end
        end
        data
      end

      private

      # make_conversion creates a Conversion object from the value.
      def make_conversion(value)
        return nil unless value.is_a?(Hash)

        goal_id = value[Kameleoon::Types::Data::ConversionType::GOAL_ID]
        revenue = value[Kameleoon::Types::Data::ConversionType::REVENUE]
        revenue = revenue.to_f if revenue.is_a?(Integer)
        revenue ||= 0.0

        Kameleoon::Conversion.new(goal_id, revenue, false)
      end

      # make_custom_data creates a CustomData object from the value.
      def make_custom_data(value)
        return nil unless value.is_a?(Hash)

        index = value[Kameleoon::Types::Data::CustomDataType::INDEX]
        values = value[Kameleoon::Types::Data::CustomDataType::VALUES]
        values = [values] if values.is_a?(String)

        Kameleoon::CustomData.new(index, *values)
      end
    end
  end
end
