# Application Layer - Use Case for creating an audit event

require_relative '../../domain/entities/audit_event'

module Application
  module UseCases
    class CreateAuditEvent
      def initialize(audit_event_repository:)
        @audit_event_repository = audit_event_repository
      end

      def execute(entity_type:, entity_id:, action:, details:, status:, timestamp: nil)
        # Create domain entity
        audit_event = Domain::Entities::AuditEvent.new(
          entity_type: entity_type,
          entity_id: entity_id,
          action: action,
          details: details,
          status: status,
          timestamp: timestamp
        )

        # Persist using repository
        saved_event = @audit_event_repository.save(audit_event)

        saved_event
      rescue ArgumentError => e
        raise e
      rescue StandardError => e
        raise StandardError, "Error al crear evento de auditoría: #{e.message}"
      end
    end
  end
end
