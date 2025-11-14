ENV['RACK_ENV'] = 'test'
ENV['AUDITORIA_SERVICE_URL'] = 'http://localhost:4003'

require 'bundler/setup'
Bundler.require(:test)

require_relative '../config/environment'
require_relative '../app/controllers/clientes_controller'

require 'rack/test'
require 'webmock/rspec'
require 'database_cleaner/active_record'

# Disable external HTTP requests by default
WebMock.disable_net_connect!(allow_localhost: false)

RSpec.configure do |config|
  # Include Rack::Test methods
  config.include Rack::Test::Methods

  # Define the app for Rack::Test
  def app
    ClientesController
  end

  # Database Cleaner configuration
  config.before(:suite) do
    # Load database schema for test database
    ActiveRecord::Schema.verbose = false
    load File.join(__dir__, '../db/schema.rb')

    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # RSpec expectations configuration
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # RSpec mocks configuration
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
