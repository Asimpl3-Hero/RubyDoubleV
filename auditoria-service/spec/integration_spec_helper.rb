ENV['RACK_ENV'] = 'test'
ENV['MONGO_URL'] = 'localhost:27017'
ENV['MONGO_DATABASE'] = 'auditoria_test_db'
ENV['MONGO_USERNAME'] = 'admin'
ENV['MONGO_PASSWORD'] = 'factumarket_secure_2025'

require 'bundler/setup'
Bundler.require(:test)

require_relative '../config/environment'
require_relative '../app/interfaces/http/auditoria_controller'

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

  # MongoDB cleanup (skip if MongoDB is not available)
  config.before(:suite) do
    begin
      # Clean test database before suite
      options = {
        database: 'auditoria_test_db',
        server_selection_timeout: 2
      }

      # Add authentication if credentials are provided
      if ENV['MONGO_USERNAME'] && ENV['MONGO_PASSWORD']
        options[:user] = ENV['MONGO_USERNAME']
        options[:password] = ENV['MONGO_PASSWORD']
        options[:auth_source] = 'admin'
      end

      mongo_client = Mongo::Client.new(['localhost:27017'], options)
      mongo_client[:audit_events].drop
      mongo_client.close
    rescue Mongo::Error::NoServerAvailable, Mongo::Error::OperationFailure => e
      puts "⚠️  MongoDB not available or auth failed - skipping database cleanup (tests may use mocks)"
    end
  end

  config.after(:each) do
    begin
      # Clean test database after each test
      options = {
        database: 'auditoria_test_db',
        server_selection_timeout: 2
      }

      # Add authentication if credentials are provided
      if ENV['MONGO_USERNAME'] && ENV['MONGO_PASSWORD']
        options[:user] = ENV['MONGO_USERNAME']
        options[:password] = ENV['MONGO_PASSWORD']
        options[:auth_source] = 'admin'
      end

      mongo_client = Mongo::Client.new(['localhost:27017'], options)
      mongo_client[:audit_events].delete_many
      mongo_client.close
    rescue Mongo::Error::NoServerAvailable, Mongo::Error::OperationFailure, NoMethodError => e
      # Skip cleanup if MongoDB is not available, auth failed, or using mocks
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
