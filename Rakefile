# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test_unit_data_converter) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/test_unit_data_converter.rb']
  t.warning = false
end

Rake::TestTask.new(:test_unit_kameleoon_provider) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/test_unit_kameleoon_provider.rb']
  t.warning = false
end

Rake::TestTask.new(:test_unit_kameleoon_resolver) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/test_unit_kameleoon_resolver.rb']
  t.warning = false
end

Rake::TestTask.new(:test_unit_types) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/test_unit_types.rb']
  t.warning = false
end

Rake::TestTask.new(:test_integration_example) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/test_integration_example.rb']
  t.warning = false
end

task default: :unit_test
