require_relative 'rabbit_connection'
require 'json'

module Messaging
  class AuditPublisher
    class << self
      # Publish audit event to RabbitMQ asynchronously
      def publish(entity_type:, entity_id:, action:, details:, status:)
        event = {
          entity_type: entity_type,
          entity_id: entity_id,
          action: action,
          details: details,
          status: status,
          timestamp: Time.now.utc.iso8601,
          service: ENV['SERVICE_NAME'] || 'unknown-service'
        }

        queue = RabbitConnection.instance.audit_queue

        queue.publish(
          event.to_json,
          persistent: true,
          content_type: 'application/json',
          timestamp: Time.now.to_i
        )

        puts "[AuditPublisher] Event published: #{action} on #{entity_type}"
        true
      rescue StandardError => e
        # Log error but don't fail the main operation
        puts "[AuditPublisher] Failed to publish event: #{e.message}"
        puts "[AuditPublisher] Backtrace: #{e.backtrace.first(3).join("\n")}"
        false
      end

      # Bulk publish multiple events
      def publish_batch(events)
        return 0 if events.empty?

        queue = RabbitConnection.instance.audit_queue
        published_count = 0

        events.each do |event|
          event[:timestamp] ||= Time.now.utc.iso8601
          event[:service] ||= ENV['SERVICE_NAME'] || 'unknown-service'

          queue.publish(
            event.to_json,
            persistent: true,
            content_type: 'application/json',
            timestamp: Time.now.to_i
          )

          published_count += 1
        end

        puts "[AuditPublisher] Batch published: #{published_count} events"
        published_count
      rescue StandardError => e
        puts "[AuditPublisher] Batch publish failed: #{e.message}"
        published_count
      end
    end
  end
end
