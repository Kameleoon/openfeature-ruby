# frozen_string_literal: true

require 'open_feature/sdk/provider/error_code'
require 'open_feature/sdk/provider/resolution_details'
require 'open_feature/sdk/provider/reason'
require 'open_feature/sdk/provider'
require 'kameleoon/data_converter'

module Kameleoon
  VARIABLE_KEY = 'variableKey'

  # Resolver interface which contains method for evaluations based on provided data
  class Resolver
    def resolve(flag: String, default_value:, evaluation_context: OpenFeature::SDK::EvaluationContext)
      raise NotImplementedError, 'Subclasses must implement the resolve method'
    end
  end

  # KameleoonResolver makes evaluations based on provided data, conforms to Resolver interface
  class KameleoonResolver < Resolver
    Provider = OpenFeature::SDK::Provider

    def initialize(client)
      @client = client
    end

    # Main method for getting resolution details based on provided data.
    def resolve(allowed_classes: Array, flag_key: String, default_value:, evaluation_context: nil)
      if !evaluation_context.is_a?(OpenFeature::SDK::EvaluationContext) ||
        (visitor_code = get_targeting_key(evaluation_context)).nil? || visitor_code.empty?
        return make_resolution_error(
          default_value,
          Provider::ErrorCode::TARGETING_KEY_MISSING,
          'The TargetingKey is required in context and cannot be omitted.')
      end

      # Add targeting data from context to KameleoonClient by visitor code
      @client.add_data(visitor_code, *DataConverter.to_kameleoon(evaluation_context))

      # Get a variation (main SDK method)
      variation = @client.get_variation(visitor_code, flag_key)

      # Get a variant (variation key)
      variant = variation.key

      # Get variableKey if it's provided in context or any first in variation.
      # It's the responsibility of the client to have only one variable per variation if
      # variableKey is not provided.
      variable_key = get_variable_key(evaluation_context, variation.variables)

      # Get value by variable key
      value = variation.variables[variable_key]&.value

      if value.nil? || variable_key.empty?
        return make_resolution_error(
          default_value,
          Provider::ErrorCode::FLAG_NOT_FOUND,
          make_error_description(variant, variable_key),
          variant: variant)
      end

      # Check if the variable value has a required type
      if allowed_classes.any? { |klass| value.is_a?(klass) }
        return Provider::ResolutionDetails.new(
          value: value,
          reason: Provider::Reason::STATIC,
          variant: variant)
      else
        make_resolution_error(
          default_value,
          Provider::ErrorCode::TYPE_MISMATCH,
          'The type of value received is different from the requested value.',
          variant: variant)
      end
    rescue Kameleoon::Exception::FeatureError => e
      make_resolution_error(default_value, Provider::ErrorCode::FLAG_NOT_FOUND, e.message)
    rescue Kameleoon::Exception::VisitorCodeInvalid => e
      make_resolution_error(default_value, Provider::ErrorCode::INVALID_CONTEXT, e.message)
    rescue StandardError => e
      make_resolution_error(default_value, Provider::ErrorCode::GENERAL, e.message, variant: variant)
    end

    private

    # Helper method to get the targeting key from the context.
    def get_targeting_key(evaluation_context)
      targeting_key = evaluation_context.targeting_key
      targeting_key if targeting_key.is_a?(String)
    end

    # Helper method to get the variable key from the context or variables map.
    def get_variable_key(context, variables)
      variable_key = context.field(VARIABLE_KEY)
      variable_key = variables.keys.first if variable_key.nil? || variable_key.empty?
      variable_key
    end

    # Helper method to generate an error description based on the variant and variable key.
    def make_error_description(variant, variable_key)
      if variable_key.nil? || variable_key.empty?
        "The variation '#{variant}' has no variables"
      else
        "The value for provided variable key '#{variable_key}' isn't found in variation '#{variant}'"
      end
    end

    # Helper method to generate a resolution details with error.
    def make_resolution_error(default_value, error_code, error_message, variant: nil)
      Provider::ResolutionDetails.new(
        value: default_value,
        error_code: error_code,
        error_message: error_message,
        reason: Provider::Reason::ERROR,
        variant: variant)
    end
  end
end
