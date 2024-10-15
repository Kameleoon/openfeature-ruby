# Kameleoon OpenFeature provider for Ruby

The Kameleoon OpenFeature provider for Ruby allows you to connect your OpenFeature Ruby implementation to Kameleoon without installing the Ruby Kameleoon SDK.

> [!WARNING]
> This is a beta version. Breaking changes may be introduced before general release.

## Supported Ruby versions

This version of the SDK is built for the following targets:

* Ruby 3.1.4 and above.

## Get started

This section explains how to install, configure, and customize the Kameleoon OpenFeature provider.

### Install dependencies

First, install the required dependencies in your application.

```sh
gem install bundler
bundle install
```

### Usage

The following example shows how to use the Kameleoon provider with the OpenFeature SDK.

```ruby
require 'kameleoon-client'
require 'open_feature/sdk'

client_config = Kameleoon::KameleoonClientConfig.new(
  'clientId',
  'clientSecret',
  top_level_domain: 'topLevelDomain',
)

provider = Kameleoon::KameleoonProvider.new('siteCode', config: client_config)
OpenFeature::SDK.configure do |config|
  config.set_provider(provider)
end

client = OpenFeature::SDK.build_client

data_dictionary = {
  'targeting_key' => 'visitorCode',
  'variableKey' => 'variableKey' 
}
eval_context = OpenFeature::SDK::EvaluationContext.new(**data_dictionary)

resolution_details = client.fetch_integer_value(flag_key: 'featureKey', default_value: 5,
                                                           evaluation_context: eval_context)
number_of_recommended_products = resolution_details.value

puts "Number of recommended products: #{number_of_recommended_products}"
```

#### Customize the Kameleoon provider

You can customize the Kameleoon provider by changing the `KameleoonClientConfig` object that you passed to the constructor above. For example:

```ruby
client_config = Kameleoon::KameleoonClientConfig.new(
  'clientId',
  'clientSecret',
  top_level_domain: 'topLevelDomain',
  refresh_interval_minute: 1,    # Optional field
  session_duration_minute: 5,    # Optional field
)

provider = Kameleoon::KameleoonProvider.new('siteCode', config: client_config)
```
> [!NOTE]
> For additional configuration options, see the [Kameleoon documentation](https://developers.kameleoon.com/feature-management-and-experimentation/web-sdks/ruby-sdk/#example-code).

## EvaluationContext and Kameleoon Data

Kameleoon uses the concept of associating `Data` to users, while the OpenFeature SDK uses the concept of an `EvaluationContext`, which is a dictionary of string keys and values. The Kameleoon provider maps the `EvaluationContext` to the Kameleoon `Data`.

> [!NOTE]
> To get the evaluation for a specific visitor, set the `targeting_key` value for the `EvaluationContext` to the visitor code (user ID). If the value is not provided, then the `defaultValue` parameter will be returned.

```ruby
values = { 'targeting_key' => 'userId' }

eval_context = OpenFeature::SDK::EvaluationContext.new(**values)
```

The Kameleoon provider provides a few predefined parameters that you can use to target a visitor from a specific audience and track each conversion. These are:

| Parameter                 | Description                                                                                                                                                           |
|---------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `Data::Type::CUSTOM_DATA` | The parameter is used to set [`CustomData`](https://developers.kameleoon.com/feature-management-and-experimentation/web-sdks/ruby-sdk/#customdata) for a visitor.     |
| `Data::Type::CONVERSION`  | The parameter is used to track a [`Conversion`](https://developers.kameleoon.com/feature-management-and-experimentation/web-sdks/ruby-sdk/#conversion) for a visitor. |

### Data::Type::CUSTOM_DATA

Use `Data::Type::CUSTOM_DATA` to set [`CustomData`](https://developers.kameleoon.com/feature-management-and-experimentation/web-sdks/ruby-sdk/#customdata) for a visitor. The `Data::Type::CUSTOM_DATA` field has the following parameters:

| Parameter                      | Type    | Description                                                       |
|--------------------------------|---------|-------------------------------------------------------------------|
| `Data::CustomDataType::INDEX`  | Integer | Index or ID of the custom data to store. This field is mandatory. |
| `Data::CustomDataType::VALUES` | String  | Value of the custom data to store. This field is mandatory.       |

#### Example

```ruby
custom_data_dictionary = {
  'targeting_key' => 'userId',
  Kameleoon::Types::Data::Type::CUSTOM_DATA => {
      Kameleoon::Types::Data::CustomDataType::INDEX => 1,
      Kameleoon::Types::Data::CustomDataType::VALUES => '10'
    }
}

eval_context = OpenFeature::SDK::EvaluationContext.new(**custom_data_dictionary)
```

### Data::Type::CONVERSION

Use `Data::Type::CONVERSION` to track a [`Conversion`](https://developers.kameleoon.com/feature-management-and-experimentation/web-sdks/ruby-sdk/#conversion) for a visitor. The `Data::Type::CONVERSION` field has the following parameters:

| Parameter                       | Type    | Description                                                     |
|---------------------------------|---------|-----------------------------------------------------------------|
| `Data::ConversionType::GOAL_ID` | Integer | Identifier of the goal. This field is mandatory.                |
| `Data::ConversionType::REVENUE` | Float   | Revenue associated with the conversion. This field is optional. |

#### Example

```ruby
conversion_dictionary = {
  Kameleoon::Types::Data::ConversionType::GOAL_ID => 1,
  Kameleoon::Types::Data::ConversionType::REVENUE => 200
}

eval_context = OpenFeature::SDK::EvaluationContext.new(**{
    'targeting_key' => 'userId',
    Kameleoon::Types::Data::Type::CONVERSION => conversion_dictionary
})
```

### Use multiple Kameleoon Data types

You can provide many different kinds of Kameleoon data within a single `EvaluationContext` instance.

For example, the following code provides one `Data::Type::CONVERSION` instance and two `Data::Type::CUSTOM_DATA` instances.

```ruby
data_dictionary = {
  'targeting_key' => 'userId',
  Kameleoon::Types::Data::Type::CONVERSION => {
    Kameleoon::Types::Data::ConversionType::GOAL_ID => 1,
    Kameleoon::Types::Data::ConversionType::REVENUE => 200
  },
  Kameleoon::Types::Data::Type::CUSTOM_DATA => [
    {
      Kameleoon::Types::Data::CustomDataType::INDEX => 1,
      Kameleoon::Types::Data::CustomDataType::VALUES => ['10', '30']
    },
    {
      Kameleoon::Types::Data::CustomDataType::INDEX => 2,
      Kameleoon::Types::Data::CustomDataType::VALUES => '20'
    }
  ]
}

eval_context = OpenFeature::SDK::EvaluationContext.new(**data_dictionary)
```
