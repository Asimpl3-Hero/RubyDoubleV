# Application Layer - Use Case (Clean Architecture)
# Orchestrates business logic for creating a cliente

require_relative '../../domain/entities/cliente'
require_relative '../../../../shared/messaging/audit_publisher' unless defined?(Messaging::AuditPublisher)

module Application
  module UseCases
    class CreateCliente
      def initialize(cliente_repository:, auditoria_service_url:)
        @cliente_repository = cliente_repository
        @auditoria_service_url = auditoria_service_url
      end

      def execute(nombre:, identificacion:, correo:, direccion:)
        # Check if cliente already exists
        existing_cliente = @cliente_repository.find_by_identificacion(identificacion)
        if existing_cliente
          raise StandardError, "Cliente con identificación #{identificacion} ya existe"
        end

        # Create domain entity
        cliente = Domain::Entities::Cliente.new(
          nombre: nombre,
          identificacion: identificacion,
          correo: correo,
          direccion: direccion
        )

        # Persist using repository
        saved_cliente = @cliente_repository.save(cliente)

        # Register audit event
        register_audit_event(
          entity_type: 'cliente',
          entity_id: saved_cliente.id,
          action: 'CREATE',
          details: "Cliente creado: #{saved_cliente.nombre}",
          status: 'SUCCESS'
        )

        saved_cliente
      rescue StandardError => e
        # Register audit event for failure
        register_audit_event(
          entity_type: 'cliente',
          entity_id: nil,
          action: 'CREATE',
          details: "Error al crear cliente: #{e.message}",
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
