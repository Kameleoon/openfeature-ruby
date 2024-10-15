# frozen_string_literal: true

require 'minitest/autorun'
require 'mocha/minitest'
require 'kameleoon/kameleoon_client'
require 'kameleoon/data_converter'
require 'kameleoon/types'
require 'open_feature/sdk/evaluation_context'
require 'kameleoon/resolver'
require 'open_feature/sdk/provider/error_code'

class TestKameleoonResolver < Minitest::Test
  include Kameleoon
  include Kameleoon::Types
  include OpenFeature::SDK
  include OpenFeature::SDK::Provider

  TARGETING_KEY = 'targeting_key'

  def setup
    @client_mock = mock('KameleoonClient')
    @resolver = KameleoonResolver.new(@client_mock)
  end

  def test_resolve_with_nil_context_returns_error_for_missing_targeting_key
    # arrange
    flag_key = 'testFlag'
    default_value = 'defaultValue'
    expected_error_code = ErrorCode::TARGETING_KEY_MISSING
    expected_error_message = 'The TargetingKey is required in context and cannot be omitted.'

    # act
    result = @resolver.resolve(allowed_classes: [], flag_key: flag_key, default_value: default_value)

    # assert
    assert_result(result, default_value, nil, expected_error_code, expected_error_message)
  end

  def test_resolve_no_match_variables_returns_error_for_flag_not_found
    # arrange
    flag_key = 'testFlag'
    default_value = 42
    visitor_code = 'testVisitor'
    variable = Kameleoon::Types::Variable.new('key', 'STRING', 'str')

    test_cases = [
      { variation: Kameleoon::Types::Variation.new("on", -1, -1, {}), add_variable_key: false,
        expected_error_msg: "The variation 'on' has no variables" },
      { variation: Kameleoon::Types::Variation.new("var", -1, -1, {variable.key => variable }),
        add_variable_key: true,
        expected_error_msg: "The value for provided variable key 'variableKey' isn't found in variation 'var'" }
    ]

    test_cases.each do |tc|
      @client_mock.expects(:get_variation).with(visitor_code, flag_key).returns(tc[:variation])
      @client_mock.expects(:add_data).with(visitor_code, anything).returns(nil)

      eval_context = { TARGETING_KEY => visitor_code }
      eval_context['variableKey'] = 'variableKey' if tc[:add_variable_key]
      eval_context = EvaluationContext.new(**eval_context)

      expected_error_code = ErrorCode::FLAG_NOT_FOUND
      expected_error_message = tc[:expected_error_msg]

      # act
      result = @resolver.resolve(allowed_classes: [Integer], flag_key: flag_key, default_value: default_value,
                                 evaluation_context: eval_context)

      # assert
      assert_result(result, default_value, tc[:variation].key, expected_error_code, expected_error_message)
    end
  end

  def test_resolve_mismatch_type_returns_error_type_mismatch
    # arrange
    flag_key = 'testFlag'
    expected_variant = 'on'
    default_value = 42
    visitor_code = 'testVisitor'

    test_cases = [
      Kameleoon::Types::Variable.new('key', 'BOOLEAN', true),
      Kameleoon::Types::Variable.new('key', 'STRING', 'string'),
      Kameleoon::Types::Variable.new('key', 'NUMBER', 10.0)
    ]

    test_cases.each do |return_variable|
      @client_mock.expects(:get_variation).with(visitor_code, flag_key)
                  .returns(Kameleoon::Types::Variation.new(expected_variant, -1, -1, { 'key' => return_variable }))
      @client_mock.expects(:add_data).with(visitor_code, anything).returns(nil)

      eval_context = { TARGETING_KEY => visitor_code }
      eval_context = EvaluationContext.new(**eval_context)
      expected_error_code = ErrorCode::TYPE_MISMATCH
      expected_error_message = 'The type of value received is different from the requested value.'

      # act
      result = @resolver.resolve(allowed_classes: [Integer], flag_key: flag_key, default_value: default_value,
                                 evaluation_context: eval_context)
      # assert
      assert_result(result, default_value, expected_variant, expected_error_code, expected_error_message)
    end
  end

  def test_resolve_kameleoon_exception_flag_not_found
    # arrange
    flag_key = 'testFlag'
    visitor_code = 'testVisitor'
    default_value = 42

    exception = Exception::FeatureNotFound.new('featureException')
    @client_mock.expects(:add_data).with(visitor_code, anything).returns(nil)
    @client_mock.expects(:get_variation).raises(exception)

    eval_context = { TARGETING_KEY => visitor_code }
    eval_context = EvaluationContext.new(**eval_context)
    expected_error_code = ErrorCode::FLAG_NOT_FOUND
    expected_error_message = 'featureException'

    # act
    result = @resolver.resolve(allowed_classes: [Integer], flag_key: flag_key, default_value: default_value,
                               evaluation_context: eval_context)

    # assert
    assert_result(result, default_value, nil, expected_error_code, expected_error_message)
  end

  def test_resolve_kameleoon_exception_visitor_code_invalid
    # arrange
    flag_key = 'testFlag'
    visitor_code = 'testVisitor'
    default_value = 42

    exception = Exception::VisitorCodeInvalid.new('visitorCodeInvalid')
    @client_mock.expects(:add_data).raises(exception)

    eval_context = { TARGETING_KEY => visitor_code }
    eval_context = EvaluationContext.new(**eval_context)
    expected_error_code = ErrorCode::INVALID_CONTEXT
    expected_error_message = 'visitorCodeInvalid'

    # act
    result = @resolver.resolve(allowed_classes: [Integer], flag_key: flag_key, default_value: default_value,
                               evaluation_context: eval_context)

    # assert
    assert_result(result, default_value, nil, expected_error_code, expected_error_message)
  end

  def test_resolve_returns_result_details
    # arrange
    flag_key = 'testFlag'
    visitor_code = 'testVisitor'
    expected_variant = 'variant'

    test_cases = [
      { variable_key: nil, variables: { 'k' => Kameleoon::Types::Variable.new('key', 'NUMBER', 10) },
        expected_value: 10, default_value: 9, allowed_classes: [Integer] },
      { variable_key: nil, variables: { 'k1' => Kameleoon::Types::Variable.new('key', 'STRING', 'str') },
        expected_value: 'str', default_value: 'st', allowed_classes: [String] },
      { variable_key: nil, variables: { 'k2' => Kameleoon::Types::Variable.new('key', 'BOOLEAN', true) },
        expected_value: true, default_value: false, allowed_classes: [FalseClass, TrueClass] },
      { variable_key: nil, variables: { 'k3' => Kameleoon::Types::Variable.new('key', 'NUMBER', 10.0) },
        expected_value: 10.0, default_value: 11.0, allowed_classes: [Float] },
      { variable_key: 'varKey', variables: { 'varKey' => Kameleoon::Types::Variable.new('key', 'NUMBER', 10.0) },
        expected_value: 10.0, default_value: 11.0, allowed_classes: [Float] }
    ]

    test_cases.each do |tc|
      @client_mock.expects(:add_data).with(visitor_code, anything).returns(nil)
      @client_mock.expects(:get_variation).with(visitor_code, flag_key)
                  .returns(Kameleoon::Types::Variation.new(expected_variant, -1, -1, tc[:variables]))

      eval_context = { TARGETING_KEY => visitor_code }
      eval_context['variableKey'] = tc[:variable_key] unless tc[:variable_key].nil?
      eval_context = EvaluationContext.new(**eval_context)

      # act
      result = @resolver.resolve(allowed_classes: tc[:allowed_classes], flag_key: flag_key,
                                 default_value: tc[:default_value], evaluation_context: eval_context)

      # assert
      assert_result(result, tc[:expected_value], expected_variant, nil, nil)
    end
  end

  def assert_result(result, expected_value, expected_variant, expected_error_code, expected_error_message)
    if expected_value.nil?
      assert_nil result.value
    else
      assert_equal expected_value, result.value
    end
    if expected_error_code.nil?
      assert_nil result.error_code
    else
      assert_equal expected_error_code, result.error_code
    end
    if expected_error_message.nil?
      assert_nil result.error_message
    else
      assert_includes result.error_message, expected_error_message
    end
    if expected_variant.nil?
      assert_nil result.variant
    else
      assert_equal expected_variant, result.variant
    end
  end
end
