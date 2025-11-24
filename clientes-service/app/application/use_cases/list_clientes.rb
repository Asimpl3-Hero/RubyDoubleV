# Application Layer - Use Case for listing all clientes

require_relative '../../../../shared/messaging/audit_publisher' unless defined?(Messaging::AuditPublisher)

module Application
  module UseCases
    class ListClientes
      def initialize(cliente_repository:, auditoria_service_url:)
        @cliente_repository = cliente_repository
        @auditoria_service_url = auditoria_service_url
      end

      def execute
        clientes = @cliente_repository.find_all

        # Register audit event
        register_audit_event(
          entity_type: 'cliente',
          entity_id: nil,
          action: 'LIST',
          details: "Listado de clientes: #{clientes.count} registros",
          status: 'SUCCESS'
        )

        clientes
      rescue StandardError => e
        # Register audit event for failure
        register_audit_event(
          entity_type: 'cliente',
          entity_id: nil,
          action: 'LIST',
          details: "Error al listar clientes: #{e.message}",
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
