# Mock for AuditPublisher in tests - doesn't require RabbitMQ
module Messaging
  class AuditPublisherMock
    @published_events = []

    class << self
      attr_reader :published_events

      def publish(entity_type:, entity_id:, action:, details:, status:)
        event = {
          entity_type: entity_type,
          entity_id: entity_id,
          action: action,
          details: details,
          status: status,
          timestamp: Time.now.utc.iso8601,
          service: ENV['SERVICE_NAME'] || 'test-service'
        }

        @published_events << event
        puts "[AuditPublisherMock] Event published: #{action} on #{entity_type}"
        true
      end

      def reset!
        @published_events = []
      end

      def last_event
        @published_events.last
      end

      def events_count
        @published_events.size
      end

      def find_events(action: nil, entity_type: nil, status: nil)
        results = @published_events
        results = results.select { |e| e[:action] == action } if action
        results = results.select { |e| e[:entity_type] == entity_type } if entity_type
        results = results.select { |e| e[:status] == status } if status
        results
      end
    end
  end
end
