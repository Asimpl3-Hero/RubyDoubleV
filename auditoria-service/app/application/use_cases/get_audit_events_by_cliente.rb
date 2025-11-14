# Application Layer - Use Case for retrieving audit events by cliente ID

module Application
  module UseCases
    class GetAuditEventsByCliente
      def initialize(audit_event_repository:)
        @audit_event_repository = audit_event_repository
      end

      def execute(cliente_id:)
        events = @audit_event_repository.find_by_cliente_id(cliente_id)

        events
      rescue StandardError => e
        raise StandardError, "Error al consultar eventos de auditoría: #{e.message}"
      end
    end
  end
end
