require 'bunny'
require 'singleton'

module Messaging
  class RabbitConnection
    include Singleton

    attr_reader :connection, :channel

    def initialize
      @connection = nil
      @channel = nil
      @mutex = Mutex.new
    end

    def connect
      @mutex.synchronize do
        return if @connection && @connection.open?

        @connection = Bunny.new(ENV['RABBITMQ_URL'] || 'amqp://localhost:5672')
        @connection.start

        @channel = @connection.create_channel
        @channel.prefetch(1) # Fair dispatch

        puts "[RabbitMQ] Connected successfully to #{ENV['RABBITMQ_URL']}"
      end
    rescue StandardError => e
      puts "[RabbitMQ] Connection failed: #{e.message}"
      raise e
    end

    def disconnect
      @mutex.synchronize do
        @channel&.close
        @connection&.close
        @channel = nil
        @connection = nil
        puts "[RabbitMQ] Disconnected"
      end
    rescue StandardError => e
      puts "[RabbitMQ] Disconnect error: #{e.message}"
    end

    def ensure_connected
      connect unless @connection&.open?
      @channel
    end

    # Declare audit events queue
    def audit_queue
      ensure_connected
      @channel.queue('audit_events', durable: true, arguments: {
        'x-message-ttl' => 86400000, # 24 hours
        'x-max-length' => 100000     # Max 100k messages
      })
    end
  end
end
