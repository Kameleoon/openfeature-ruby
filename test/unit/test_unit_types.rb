# frozen_string_literal: true

require 'minitest/autorun'
require 'kameleoon/types'

class TestTypes < Minitest::Test
  Data = Kameleoon::Types::Data
  def test_proper_values
    assert_equal 'conversion', Data::Type::CONVERSION
    assert_equal 'customData', Data::Type::CUSTOM_DATA

    assert_equal 'index', Data::CustomDataType::INDEX
    assert_equal 'values', Data::CustomDataType::VALUES

    assert_equal 'goalId', Data::ConversionType::GOAL_ID
    assert_equal 'revenue', Data::ConversionType::REVENUE
  end
end
