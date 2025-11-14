# Application Layer - Use Case for listing all audit events

module Application
  module UseCases
    class ListAuditEvents
      def initialize(audit_event_repository:)
        @audit_event_repository = audit_event_repository
      end

      def execute(action: nil, status: nil, limit: 100)
        events = if action
                   @audit_event_repository.find_by_action(action: action, limit: limit)
                 elsif status
                   @audit_event_repository.find_by_status(status: status, limit: limit)
                 else
                   @audit_event_repository.find_all(limit: limit)
                 end

        events
      rescue StandardError => e
        raise StandardError, "Error al listar eventos de auditoría: #{e.message}"
      end
    end
  end
end
