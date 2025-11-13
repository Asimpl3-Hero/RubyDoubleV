# Application Layer - Use Case for retrieving a factura

require 'httparty'

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
          entity_type: 'Factura',
          entity_id: factura.id,
          action: 'READ',
          details: "Factura #{factura.numero_factura} consultada",
          status: 'SUCCESS'
        )

        factura
      rescue StandardError => e
        # Register audit event for failure
        register_audit_event(
          entity_type: 'Factura',
          entity_id: id,
          action: 'READ',
          details: "Error al consultar factura: #{e.message}",
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
