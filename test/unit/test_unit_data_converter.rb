# frozen_string_literal: true

require 'minitest/autorun'
require 'kameleoon/kameleoon_client'
require 'kameleoon/data_converter'
require 'kameleoon/types'
require 'open_feature/sdk/evaluation_context'

class TestDataConverter < Minitest::Test
  include Kameleoon
  include Kameleoon::Types
  Data = Kameleoon::Types::Data
  EvaluationContext = OpenFeature::SDK::EvaluationContext
  def setup
  end

  def test_to_kameleoon_null_context_returns_empty
    context = nil
    result = DataConverter.to_kameleoon(context)
    assert_empty result
  end

  def test_to_kameleoon_with_conversion_data_returns_conversion_data
    tests = [
      { name: 'WithRevenue', add_revenue: true },
      { name: 'WithoutRevenue', add_revenue: false }
    ]

    tests.each do |tt|
      rand_goal_id = rand(1..1000)
      rand_revenue = rand * 1000

      conversion_data = { Data::ConversionType::GOAL_ID => rand_goal_id }
      conversion_data[Data::ConversionType::REVENUE] = rand_revenue if tt[:add_revenue]

      context = { Data::Type::CONVERSION => conversion_data }
      eval_context = EvaluationContext.new(**context)
      result = DataConverter.to_kameleoon(eval_context)

      assert_equal 1, result.size
      conversion = result.first
      assert_instance_of Kameleoon::Conversion, conversion
      assert_equal rand_goal_id, conversion.goal_id

      if tt[:add_revenue]
        assert_equal rand_revenue, conversion.revenue
      end
    end
  end

  def test_to_kameleoon_with_custom_data_returns_custom_data
    tests = [
      { name: 'EmptyValues', expected_index: rand(1..1000), expected_values: [] },
      { name: 'SingleValue', expected_index: rand(1..1000), expected_values: ['v1'] },
      { name: 'MultipleValues', expected_index: rand(1..1000), expected_values: %w[v1 v2 v3] }
    ]

    tests.each do |tt|
      custom_data = {
        Data::CustomDataType::INDEX => tt[:expected_index],
        Data::CustomDataType::VALUES => tt[:expected_values]
      }

      context = { Data::Type::CUSTOM_DATA => custom_data }
      eval_context = EvaluationContext.new(**context)

      result = DataConverter.to_kameleoon(eval_context)

      assert_equal 1, result.size
      custom_data_obj = result.first
      assert_instance_of Kameleoon::CustomData, custom_data_obj
      assert_equal tt[:expected_index], custom_data_obj.id
      assert_equal tt[:expected_values], custom_data_obj.values
    end
  end

  def test_to_kameleoon_data_all_types_returns_all_data
    goal_id1 = rand(1..1000)
    goal_id2 = rand(1..1000)
    index1 = rand(1..1000)
    index2 = rand(1..1000)

    context_data = {
      Data::Type::CONVERSION => [
        { Data::ConversionType::GOAL_ID => goal_id1 },
        { Data::ConversionType::GOAL_ID => goal_id2 }
      ],
      Data::Type::CUSTOM_DATA => [
        { Data::CustomDataType::INDEX => index1 },
        { Data::CustomDataType::INDEX => index2 }
      ]
    }

    eval_context = EvaluationContext.new(**context_data)

    result = DataConverter.to_kameleoon(eval_context)

    conversions = result.select { |item| item.is_a?(Kameleoon::Conversion) }
    custom_data = result.select { |item| item.is_a?(Kameleoon::CustomData) }

    assert_equal 4, result.size
    assert_equal goal_id1, conversions[0].goal_id
    assert_equal goal_id2, conversions[1].goal_id
    assert_equal index1, custom_data[0].id
    assert_equal index2, custom_data[1].id
  end
end
