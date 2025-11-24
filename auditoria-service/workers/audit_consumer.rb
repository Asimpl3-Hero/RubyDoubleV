#!/usr/bin/env ruby
# Worker that consumes audit events from RabbitMQ and persists them to MongoDB

require 'bundler/setup'
require 'json'
require_relative '../shared/messaging/rabbit_connection'
require_relative '../app/application/use_cases/create_audit_event'
require_relative '../app/infrastructure/persistence/mongo_audit_event_repository'

# Load environment
require 'dotenv'
Dotenv.load('.env')

module Workers
  class AuditConsumer
    def initialize
      @mongo_client = create_mongo_client
      @repository = Infrastructure::Persistence::MongoAuditEventRepository.new(@mongo_client)
      @use_case = Application::UseCases::CreateAuditEvent.new(
        audit_event_repository: @repository
      )
    end

    def start
      puts "[AuditConsumer] Starting consumer..."
      puts "[AuditConsumer] RabbitMQ URL: #{ENV['RABBITMQ_URL']}"

      # Connect to RabbitMQ with retries
      max_retries = 10
      retry_count = 0

      begin
        Messaging::RabbitConnection.instance.connect
        queue = Messaging::RabbitConnection.instance.audit_queue
        puts "[AuditConsumer] Connected to queue: #{queue.name}"
      rescue StandardError => e
        retry_count += 1
        if retry_count <= max_retries
          puts "[AuditConsumer] Connection failed (attempt #{retry_count}/#{max_retries}): #{e.message}"
          puts "[AuditConsumer] Retrying in 3 seconds..."
          sleep 3
          retry
        else
          puts "[AuditConsumer] Max retries reached. Exiting."
          exit 1
        end
      end

      puts "[AuditConsumer] Waiting for messages. To exit press CTRL+C"

      # Subscribe to messages
      queue.subscribe(manual_ack: true, block: true) do |delivery_info, _properties, body|
        process_message(body, delivery_info)
      end
    rescue Interrupt
      puts "\n[AuditConsumer] Shutting down gracefully..."
      shutdown
    rescue StandardError => e
      puts "[AuditConsumer] Fatal error: #{e.message}"
      puts e.backtrace.join("\n")
      shutdown
      exit 1
    end

    private

    def process_message(body, delivery_info)
      event = JSON.parse(body, symbolize_names: true)

      puts "[AuditConsumer] Processing event: #{event[:action]} on #{event[:entity_type]}"

      # Save to MongoDB using existing use case
      @use_case.execute(
        entity_type: event[:entity_type],
        entity_id: event[:entity_id],
        action: event[:action],
        details: event[:details],
        status: event[:status],
        timestamp: event[:timestamp]
      )

      # Acknowledge message
      channel = Messaging::RabbitConnection.instance.channel
      channel.ack(delivery_info.delivery_tag)

      puts "[AuditConsumer] Event saved successfully"
    rescue JSON::ParserError => e
      puts "[AuditConsumer] Invalid JSON: #{e.message}"
      # Reject and don't requeue invalid messages
      channel = Messaging::RabbitConnection.instance.channel
      channel.nack(delivery_info.delivery_tag, false, false)
    rescue StandardError => e
      puts "[AuditConsumer] Error processing message: #{e.message}"
      puts e.backtrace.first(5).join("\n")

      # Requeue message for retry
      channel = Messaging::RabbitConnection.instance.channel
      channel.nack(delivery_info.delivery_tag, false, true)
    end

    def shutdown
      Messaging::RabbitConnection.instance.disconnect
      @mongo_client&.close
      puts "[AuditConsumer] Disconnected"
    end

    def create_mongo_client
      mongo_url = ENV['MONGO_URL'] || 'localhost:27017'
      mongo_database = ENV['MONGO_DATABASE'] || 'auditoria_db'
      mongo_username = ENV['MONGO_USERNAME']
      mongo_password = ENV['MONGO_PASSWORD']

      options = {
        database: mongo_database,
        server_selection_timeout: 30,
        connect_timeout: 30,
        socket_timeout: 30
      }

      # Add authentication if credentials are provided
      if mongo_username && mongo_password
        options[:user] = mongo_username
        options[:password] = mongo_password
        options[:auth_source] = 'admin'
      end

      Mongo::Client.new([mongo_url], options)
    end
  end
end

# Start consumer if this file is executed directly
if __FILE__ == $PROGRAM_NAME
  consumer = Workers::AuditConsumer.new
  consumer.start
end
