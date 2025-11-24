# Set environment variables before loading application code
ENV['RACK_ENV'] = 'test'
ENV['JWT_SECRET_KEY'] = '160b6ba480729089b07d54020388926db99330c793e77fb6530262f973121077'

# Load audit publisher mock FIRST - before any application code
require_relative '../../shared/messaging/audit_publisher_mock'

# Replace real publisher with mock - this MUST happen before loading use cases
Messaging = Module.new unless defined?(Messaging)
Messaging::AuditPublisher = Messaging::AuditPublisherMock

# SimpleCov must be loaded before application code
require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/db/'
  add_group 'Domain', 'app/domain'
  add_group 'Application', 'app/application'
  add_group 'Infrastructure', 'app/infrastructure'
  add_group 'Controllers', 'app/controllers'

  track_files 'app/**/*.rb'
  minimum_coverage 80
end

require 'bundler/setup'
Bundler.require(:test)

require_relative '../app/domain/entities/cliente'
require 'webmock/rspec'

# Allow HTTP connections to auditoria service for unit tests
WebMock.allow_net_connect!

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Stub audit publisher and HTTP calls for all tests
  config.before(:each) do
    # Allow the real publisher to be called but don't actually connect to RabbitMQ
    allow_any_instance_of(Bunny::Session).to receive(:start).and_return(true)
    allow_any_instance_of(Bunny::Session).to receive(:create_channel).and_return(double('channel', prefetch: nil, queue: double('queue', publish: true)))

    # Stub HTTParty calls for backward compatibility with old tests
    allow(HTTParty).to receive(:post).and_return(double('response', success?: true, body: '{}'))
  end
end
