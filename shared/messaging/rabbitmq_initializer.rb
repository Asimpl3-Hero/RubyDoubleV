require_relative 'rabbit_connection'

# Initialize RabbitMQ connection on application startup
module Messaging
  class RabbitmqInitializer
    def self.initialize!
      puts "[RabbitMQ] Initializing connection..."

      # Connect to RabbitMQ
      RabbitConnection.instance.connect

      puts "[RabbitMQ] Initialization complete"
    rescue StandardError => e
      puts "[RabbitMQ] Warning: Failed to initialize connection: #{e.message}"
      puts "[RabbitMQ] Application will continue, but async audit logging may not work"
      # Don't fail application startup if RabbitMQ is not available
    end
  end
end

# Initialize on load
Messaging::RabbitmqInitializer.initialize!
