ENV['RACK_ENV'] = 'test'
ENV['CLIENTES_SERVICE_URL'] = 'http://localhost:4001'
ENV['AUDITORIA_SERVICE_URL'] = 'http://localhost:4003'
ENV['JWT_SECRET_KEY'] = '160b6ba480729089b07d54020388926db99330c793e77fb6530262f973121077'

require 'bundler/setup'
Bundler.require(:test)

require_relative '../config/environment'
require_relative '../app/interfaces/http/facturas_controller'

require 'rack/test'
require 'webmock/rspec'
require 'database_cleaner/active_record'

# Load audit publisher mock for integration tests
require_relative '../../shared/messaging/audit_publisher_mock'

# Replace real publisher with mock (suppress warning if already defined)
unless defined?(Messaging::AuditPublisher) && Messaging::AuditPublisher == Messaging::AuditPublisherMock
  Messaging = Module.new unless defined?(Messaging)
  Messaging.send(:remove_const, :AuditPublisher) if defined?(Messaging::AuditPublisher)
  Messaging::AuditPublisher = Messaging::AuditPublisherMock
end

# Disable external HTTP requests by default
WebMock.disable_net_connect!(allow_localhost: false)

RSpec.configure do |config|
  # Include Rack::Test methods
  config.include Rack::Test::Methods

  # Define the app for Rack::Test
  def app
    FacturasController
  end

  # Database Cleaner configuration
  config.before(:suite) do
    # Load database schema for test database
    ActiveRecord::Schema.verbose = false
    load File.join(__dir__, '../db/schema.rb')

    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    # Reset audit mock before each test
    Messaging::AuditPublisherMock.reset!

    # Stub RabbitMQ connection for integration tests
    allow_any_instance_of(Bunny::Session).to receive(:start).and_return(true)
    allow_any_instance_of(Bunny::Session).to receive(:create_channel).and_return(double('channel', prefetch: nil, queue: double('queue', publish: true)))
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # Helper methods for audit verification using mock
  config.include Module.new {
    def expect_audit_event(action:, entity_type:, status:)
      events = Messaging::AuditPublisherMock.find_events(
        action: action,
        entity_type: entity_type,
        status: status
      )
      expect(events).not_to be_empty
    end

    def audit_events_count
      Messaging::AuditPublisherMock.events_count
    end

    def last_audit_event
      Messaging::AuditPublisherMock.last_event
    end
  }

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
