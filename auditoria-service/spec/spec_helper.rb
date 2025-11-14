# Set environment variables before loading application code
ENV['RACK_ENV'] = 'test'
ENV['JWT_SECRET_KEY'] = '160b6ba480729089b07d54020388926db99330c793e77fb6530262f973121077'

# SimpleCov must be loaded before application code
require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/config/'
  add_group 'Domain', 'app/domain'
  add_group 'Application', 'app/application'
  add_group 'Infrastructure', 'app/infrastructure'
  add_group 'Controllers', 'app/controllers'

  track_files 'app/**/*.rb'
  # Lower coverage threshold since MongoDB integration tests are skipped
  minimum_coverage 30
end

require 'bundler/setup'
Bundler.require(:test)

require_relative '../app/domain/entities/audit_event'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
