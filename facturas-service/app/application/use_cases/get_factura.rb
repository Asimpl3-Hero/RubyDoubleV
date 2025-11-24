# Application Layer - Use Case for retrieving a factura

require_relative '../../../../shared/messaging/audit_publisher' unless defined?(Messaging::AuditPublisher)

module Application
  module UseCases
    class GetFactura
      def initialize(factura_repository:, auditoria_service_url:)
        @factura_repository = factura_repository
        @auditoria_service_url = auditoria_service_url
      end

      def execute(id:)
        factura = @factura_repository.find_by_id(id)

        raise StandardError, "Factura con ID #{id} no encontrada" unless factura

        # Register audit event
        register_audit_event(
          entity_type: 'factura',
          entity_id: factura.id,
          action: 'READ',
          details: "Factura #{factura.numero_factura} consultada",
          status: 'SUCCESS'
        )

        factura
      rescue StandardError => e
        # Register audit event for failure
        register_audit_event(
          entity_type: 'factura',
          entity_id: id,
          action: 'READ',
          details: "Error al consultar factura: #{e.message}",
          status: 'ERROR'
        )
        raise e
      end

      private

      def register_audit_event(entity_type:, entity_id:, action:, details:, status:)
        # Async publish to RabbitMQ - non-blocking
        Messaging::AuditPublisher.publish(
          entity_type: entity_type,
          entity_id: entity_id,
          action: action,
          details: details,
          status: status
        )
      end
    end
  end
end
