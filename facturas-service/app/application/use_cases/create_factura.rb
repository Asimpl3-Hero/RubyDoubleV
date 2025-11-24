# Application Layer - Use Case for creating a factura

require_relative '../../domain/entities/factura'
require_relative '../../domain/services/cliente_validator'
require_relative '../../../../shared/messaging/audit_publisher' unless defined?(Messaging::AuditPublisher)
require 'date'

module Application
  module UseCases
    class CreateFactura
      def initialize(factura_repository:, clientes_service_url:, auditoria_service_url:)
        @factura_repository = factura_repository
        @cliente_validator = Domain::Services::ClienteValidator.new(clientes_service_url: clientes_service_url)
        @auditoria_service_url = auditoria_service_url
      end

      def execute(cliente_id:, fecha_emision:, subtotal: nil, iva_porcentaje: 19, items: [], monto: nil)
        # Handle backward compatibility: if monto is provided but not subtotal
        subtotal_value = subtotal || monto
        raise ArgumentError, 'Se requiere subtotal o monto' unless subtotal_value

        # Parse date if it's a string
        fecha_emision_parsed = fecha_emision.is_a?(String) ? Date.parse(fecha_emision) : fecha_emision

        # Create domain entity first - this validates business rules
        # This is more efficient than calling external service first
        factura = Domain::Entities::Factura.new(
          cliente_id: cliente_id,
          fecha_emision: fecha_emision_parsed,
          subtotal: subtotal_value.to_f,
          iva_porcentaje: iva_porcentaje.to_f,
          items: items
        )

        # Validate cliente exists (only after business rules are valid)
        unless @cliente_validator.cliente_exists?(cliente_id)
          raise StandardError, "Cliente con ID #{cliente_id} no existe o no está disponible"
        end

        # Persist using repository
        saved_factura = @factura_repository.save(factura)

        # Register audit event
        register_audit_event(
          entity_type: 'factura',
          entity_id: saved_factura.id,
          action: 'CREATE',
          details: "Factura #{saved_factura.numero_factura} creada para cliente #{cliente_id}. Subtotal: #{saved_factura.subtotal}, IVA (#{saved_factura.iva_porcentaje}%): #{saved_factura.iva_valor}, Total: #{saved_factura.total}",
          status: 'SUCCESS'
        )

        saved_factura
      rescue StandardError => e
        # Register audit event for failure
        register_audit_event(
          entity_type: 'factura',
          entity_id: nil,
          action: 'CREATE',
          details: "Error al crear factura: #{e.message}",
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
