# frozen_string_literal: true

require 'minitest/autorun'
require 'mocha/minitest'
require 'kameleoon/kameleoon_provider'
require 'kameleoon/kameleoon_client_config'

class TestKameleoonProvider < Minitest::Test
  include Kameleoon
  Provider = OpenFeature::SDK::Provider

  def setup
    @client_mock = mock('KameleoonClient')
    @resolver_mock = mock('KameleoonResolver')
    @provider = KameleoonProvider.new('siteCode')
    @provider.instance_variable_set(:@client, @client_mock)
    @provider.instance_variable_set(:@resolver, @resolver_mock)
  end

  def test_metadata
    metadata = @provider.metadata
    assert_equal 'Kameleoon Provider', metadata.name
  end

  def test_create_provider_with_error
    default_value = false
    expected_error_code = Provider::ErrorCode::PROVIDER_FATAL
    expected_error_message = 'The provider is not ready to resolve flags.'
    provider = KameleoonProvider.new('')

    result = provider.fetch_boolean_value(flag_key: 'flagKey', default_value: default_value)

    assert_equal default_value, result.value
    assert_equal expected_error_code, result.error_code
    assert_equal expected_error_message, result.error_message
  end

  def test_resolve_returns_provider_not_ready
    default_value = false
    expected_error_code = Provider::ErrorCode::PROVIDER_NOT_READY
    expected_error_message = 'The provider is not ready to resolve flags.'

    result = @provider.fetch_boolean_value(flag_key: 'flagKey', default_value: default_value)

    assert_equal default_value, result.value
    assert_equal expected_error_code, result.error_code
    assert_equal expected_error_message, result.error_message
  end

  def test_resolve_boolean_value_returns_correct_value
    default_value = false
    expected_value = true
    setup_mock_resolver([TrueClass, FalseClass], default_value, expected_value)
    @provider.instance_variable_set(:@ready_state, true)

    result = @provider.fetch_boolean_value(flag_key: 'flagKey', default_value: default_value)

    assert_equal expected_value, result.value
  end

  def test_resolve_float_value_returns_correct_value
    default_value = 0.5
    expected_value = 2.5
    setup_mock_resolver([Float], default_value, expected_value)
    @provider.instance_variable_set(:@ready_state, true)

    result = @provider.fetch_float_value(flag_key: 'flagKey', default_value: default_value)
    assert_equal expected_value, result.value
  end

  def test_resolve_integer_value_returns_correct_value
    default_value = 1
    expected_value = 2
    setup_mock_resolver([Integer], default_value, expected_value)
    @provider.instance_variable_set(:@ready_state, true)

    result = @provider.fetch_integer_value(flag_key: 'flagKey', default_value: default_value)
    assert_equal expected_value, result.value
  end

  def test_resolve_string_value_returns_correct_value
    default_value = '1'
    expected_value = '2'
    setup_mock_resolver([String], default_value, expected_value)
    @provider.instance_variable_set(:@ready_state, true)

    result = @provider.fetch_string_value(flag_key: 'flagKey', default_value: default_value)
    assert_equal expected_value, result.value
  end

  def test_resolve_structure_value_returns_correct_value
    default_value = { 'k' => 10 }
    expected_value = { 'k1' => 20 }
    setup_mock_resolver([Array, Hash], default_value, expected_value)
    @provider.instance_variable_set(:@ready_state, true)

    result = @provider.fetch_object_value(flag_key: 'flagKey', default_value: default_value)
    assert_equal expected_value, result.value
  end

  def test_get_status_returns_proper_status
    @client_mock.expects(:wait_init).returns(false)
    @provider.init
    assert !@provider.ready_state

    @client_mock.expects(:wait_init).raises(StandardError.new('test'))
    @provider.init
    assert !@provider.ready_state
  end

  def test_initialize_waits_for_client_initialization
    @client_mock.expects(:wait_init).returns(true)
    @provider.init
    assert @provider.ready_state
  end

  def test_shutdown_forget_site_code
    site_code = 'testSiteCode'
    config = KameleoonClientConfig.new('clientId', 'clientSecret')
    expected_error_code = Provider::ErrorCode::PROVIDER_FATAL
    default_value = false

    provider = KameleoonProvider.new(site_code, config: config)
    client_first = provider.client
    client_to_check = KameleoonClientFactory.create(site_code, config: config)

    provider.shutdown
    result = provider.fetch_boolean_value(flag_key: 'flagKey', default_value: default_value)

    provider_second = KameleoonProvider.new(site_code, config: config)
    client_second = provider_second.client

    assert_same client_to_check, client_first
    assert client_first != client_second
    assert_equal expected_error_code, result.error_code
    assert_equal default_value, result.value
  end

  def setup_mock_resolver(allowed_classes, default_value, expected_value)
    result = Provider::ResolutionDetails.new(
      value: expected_value,
      reason: Provider::Reason::STATIC)
    @resolver_mock.expects(:resolve)
                  .with(allowed_classes: allowed_classes, flag_key: 'flagKey', default_value: default_value,
                        evaluation_context: nil)
                  .returns(result)
  end
end
