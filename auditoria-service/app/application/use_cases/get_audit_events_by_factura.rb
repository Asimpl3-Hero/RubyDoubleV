# Application Layer - Use Case for retrieving audit events by factura ID

module Application
  module UseCases
    class GetAuditEventsByFactura
      def initialize(audit_event_repository:)
        @audit_event_repository = audit_event_repository
      end

      def execute(factura_id:)
        events = @audit_event_repository.find_by_factura_id(factura_id)

        events
      rescue StandardError => e
        raise StandardError, "Error al consultar eventos de auditoría: #{e.message}"
      end
    end
  end
end
