# frozen_string_literal: true

require 'kameleoon/kameleoon_client_factory'
require 'kameleoon/resolver'
require 'open_feature/sdk/provider/provider_metadata'
require 'open_feature/sdk/provider/resolution_details'

module Kameleoon
  # The KameleoonProvider class integrates with the OpenFeature SDK to provide feature flag resolution.
  class KameleoonProvider
    Provider = OpenFeature::SDK::Provider
    NAME = 'Kameleoon Provider'

    attr_reader :client, :metadata, :ready_state

    # Initializes a new instance of the KameleoonProvider.
    #
    # @param site_code [String] The site code for the Kameleoon client.
    # @param config [KameleoonClientConfig, nil] Optional configuration for the Kameleoon client.
    # @param config_path [String, nil] Optional path to the configuration file.
    def initialize(site_code, config: nil, config_path: nil)
      @ready_state = false
      @site_code = site_code
      make_kameleoon_client(site_code, config, config_path)
      @resolver = KameleoonResolver.new(@client)
      @metadata = OpenFeature::SDK::Provider::ProviderMetadata.new(name: NAME).freeze
    end

    # Creates a Kameleoon client with the given site code and configuration.
    #
    # @param site_code [String] The site code for the Kameleoon client.
    # @param config [KameleoonClientConfig, nil] Optional configuration for the Kameleoon client.
    # @param config_path [String, nil] Optional path to the configuration file.
    # @return [void]
    private def make_kameleoon_client(site_code, config, config_path)
      begin
        @client = KameleoonClientFactory.create(site_code, config: config, config_path: config_path)
      rescue Kameleoon::Exception::KameleoonError => exception

      end
    end

    # Fetches a boolean value for the given feature flag.
    #
    # @param flag_key [String] The key of the feature flag.
    # @param default_value [Boolean] The default value to return if the flag is not found.
    # @param evaluation_context [EvaluationContext, nil] The evaluation context.
    # @return [ResolutionDetails] The resolution details.
    def fetch_boolean_value(flag_key: String, default_value:, evaluation_context: nil)
      fetch_value(allowed_classes: [TrueClass, FalseClass], flag_key: flag_key, default_value: default_value, evaluation_context: evaluation_context)
    end

    # Fetches a string value for the given feature flag.
    #
    # @param flag_key [String] The key of the feature flag.
    # @param default_value [String] The default value to return if the flag is not found.
    # @param evaluation_context [EvaluationContext, nil] The evaluation context.
    # @return [ResolutionDetails] The resolution details.
    def fetch_string_value(flag_key: String, default_value: String, evaluation_context: nil)
      fetch_value(allowed_classes: [String], flag_key: flag_key, default_value: default_value, evaluation_context: evaluation_context)
    end

    # Fetches a numeric value for the given feature flag.
    #
    # @param flag_key [String] The key of the feature flag.
    # @param default_value [Numeric] The default value to return if the flag is not found.
    # @param evaluation_context [EvaluationContext, nil] The evaluation context.
    # @return [ResolutionDetails] The resolution details.
    def fetch_number_value(flag_key: String, default_value: Numeric, evaluation_context: nil)
      fetch_value(allowed_classes: [Numeric], flag_key: flag_key, default_value: default_value, evaluation_context: evaluation_context)
    end

    # Fetches an integer value for the given feature flag.
    #
    # @param flag_key [String] The key of the feature flag.
    # @param default_value [Integer] The default value to return if the flag is not found.
    # @param evaluation_context [EvaluationContext, nil] The evaluation context.
    # @return [ResolutionDetails] The resolution details.
    def fetch_integer_value(flag_key: String, default_value: Integer, evaluation_context: nil)
      fetch_value(allowed_classes: [Integer], flag_key: flag_key, default_value: default_value, evaluation_context: evaluation_context)
    end

    # Fetches a float value for the given feature flag.
    #
    # @param flag_key [String] The key of the feature flag.
    # @param default_value [Float] The default value to return if the flag is not found.
    # @param evaluation_context [EvaluationContext, nil] The evaluation context.
    # @return [ResolutionDetails] The resolution details.
    def fetch_float_value(flag_key: String, default_value: Float, evaluation_context: nil)
      fetch_value(allowed_classes: [Float], flag_key: flag_key, default_value: default_value, evaluation_context: evaluation_context)
    end

    # Fetches an object value for the given feature flag.
    #
    # @param flag_key [String] The key of the feature flag.
    # @param default_value [Array, Hash] The default value to return if the flag is not found.
    # @param evaluation_context [EvaluationContext, nil] The evaluation context.
    # @return [ResolutionDetails] The resolution details.
    def fetch_object_value(flag_key: String, default_value:, evaluation_context: nil)
      fetch_value(allowed_classes: [Array, Hash], flag_key: flag_key, default_value: default_value, evaluation_context: evaluation_context)
    end

    # Initializes the Kameleoon client and sets the ready state.
    #
    # @return [Boolean]
    def init
      begin
        success = @client.nil? ? false : @client.wait_init
      rescue StandardError => e
        success = false
      end
      @ready_state = success
    end

    # Shuts down the Kameleoon client and resets the ready state.
    #
    # @return [void]
    def shutdown
      KameleoonClientFactory.forget(@site_code)
      @ready_state = false
      @client = nil
    end

    private

    # Fetches a value for the given feature flag based on the allowed classes.
    #
    # @param allowed_classes [Array<Class>] The allowed classes for the value.
    # @param flag_key [String] The key of the feature flag.
    # @param default_value [Any] The default value to return if the flag is not found.
    # @param evaluation_context [EvaluationContext, nil] The evaluation context.
    # @return [ResolutionDetails] The resolution details.
    def fetch_value(allowed_classes:, flag_key:, default_value:, evaluation_context:)
      if @ready_state
        @resolver.resolve(allowed_classes: allowed_classes, flag_key: flag_key, default_value: default_value,
                          evaluation_context: evaluation_context)
      else
        Provider::ResolutionDetails.new(
          value: default_value,
          error_code: @client.nil? ? Provider::ErrorCode::PROVIDER_FATAL : Provider::ErrorCode::PROVIDER_NOT_READY,
          error_message: 'The provider is not ready to resolve flags.',
          reason: Provider::Reason::ERROR)
      end
    end
  end
end
