# frozen_string_literal: true

module Kameleoon
  module Types
    module Data
      # Type is used to add different Kameleoon data types using
      # OpenFeature::SDK::EvaluationContext.
      module Type
        CONVERSION = 'conversion'
        CUSTOM_DATA = 'customData'
      end

      # CustomDataType is used to add Kameleoon::CustomData using
      # OpenFeature::SDK::EvaluationContext.
      module CustomDataType
        INDEX = 'index'
        VALUES = 'values'
      end

      # ConversionType is used to add Kameleoon::Conversion using
      # OpenFeature::SDK::EvaluationContext.
      module ConversionType
        GOAL_ID = 'goalId'
        REVENUE = 'revenue'
      end
    end
  end
end
