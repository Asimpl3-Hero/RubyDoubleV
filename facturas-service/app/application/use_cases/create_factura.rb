# Application Layer - Use Case for creating a factura

require_relative '../../domain/entities/factura'
require_relative '../../domain/services/cliente_validator'
require 'httparty'
require 'date'

module Application
  module UseCases
    class CreateFactura
      def initialize(factura_repository:, clientes_service_url:, auditoria_service_url:)
        @factura_repository = factura_repository
        @cliente_validator = Domain::Services::ClienteValidator.new(clientes_service_url: clientes_service_url)
        @auditoria_service_url = auditoria_service_url
      end

      def execute(cliente_id:, fecha_emision:, monto:, items: [])
        # Validate cliente exists
        unless @cliente_validator.cliente_exists?(cliente_id)
          raise StandardError, "Cliente con ID #{cliente_id} no existe o no está disponible"
        end

        # Parse date if it's a string
        fecha_emision_parsed = fecha_emision.is_a?(String) ? Date.parse(fecha_emision) : fecha_emision

        # Create domain entity
        factura = Domain::Entities::Factura.new(
          cliente_id: cliente_id,
          fecha_emision: fecha_emision_parsed,
          monto: monto.to_f,
          items: items
        )

        # Persist using repository
        saved_factura = @factura_repository.save(factura)

        # Register audit event
        register_audit_event(
          entity_type: 'Factura',
          entity_id: saved_factura.id,
          action: 'CREATE',
          details: "Factura #{saved_factura.numero_factura} creada para cliente #{cliente_id}. Monto: #{monto}",
          status: 'SUCCESS'
        )

        saved_factura
      rescue StandardError => e
        # Register audit event for failure
        register_audit_event(
          entity_type: 'Factura',
          entity_id: nil,
          action: 'CREATE',
          details: "Error al crear factura: #{e.message}",
          status: 'ERROR'
        )
        raise e
      end

      private

      def register_audit_event(entity_type:, entity_id:, action:, details:, status:)
        HTTParty.post(
          "#{@auditoria_service_url}/auditoria",
          body: {
            entity_type: entity_type,
            entity_id: entity_id,
            action: action,
            details: details,
            status: status,
            timestamp: Time.now.utc.iso8601
          }.to_json,
          headers: { 'Content-Type' => 'application/json' },
          timeout: 2
        )
      rescue StandardError => e
        puts "Warning: Failed to register audit event: #{e.message}"
      end
    end
  end
end
