require File.expand_path("lib/kameleoon/util/version", __dir__)

Gem::Specification.new do |spec|
  spec.name          = "kameleoon-openfeature-ruby"
  spec.version       = Kameleoon::OPENFEATURE_SDK_VERSION
  spec.summary       = "Kameleoon OpenFeature Ruby"
  spec.description   = "Kameleoon OpenFeature provider for the Ruby SDK"
  spec.authors       = ["Kameleoon"]
  spec.email         = ["sdk@kameleoon.com"]
  spec.homepage      = "https://developers.kameleoon.com/ruby-sdk.html"
  spec.files         = ["README.md"]
  spec.files         += Dir.glob("lib/**/*.rb")
  spec.require_paths = ["lib"]
  spec.license       = 'GPL-3.0'
  spec.add_dependency 'openfeature-sdk', '>= 0.4.0'
  spec.add_dependency 'kameleoon-client-ruby', '>= 3.4.0'
end
