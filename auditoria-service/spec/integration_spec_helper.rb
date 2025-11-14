ENV['RACK_ENV'] = 'test'
ENV['MONGO_URL'] = 'localhost:27017'
ENV['MONGO_DATABASE'] = 'auditoria_test_db'

require 'bundler/setup'
Bundler.require(:test)

require_relative '../config/environment'
require_relative '../app/controllers/auditoria_controller'

require 'rack/test'
require 'webmock/rspec'

# Disable external HTTP requests by default
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  # Include Rack::Test methods
  config.include Rack::Test::Methods

  # Define the app for Rack::Test
  def app
    AuditoriaController
  end

  # MongoDB cleanup
  config.before(:suite) do
    # Clean test database before suite
    mongo_client = Mongo::Client.new(['localhost:27017'], database: 'auditoria_test_db')
    mongo_client[:audit_events].drop
    mongo_client.close
  end

  config.after(:each) do
    # Clean test database after each test
    mongo_client = Mongo::Client.new(['localhost:27017'], database: 'auditoria_test_db')
    mongo_client[:audit_events].delete_many
    mongo_client.close
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
