# Application Layer - Use Case for listing facturas with optional date filter

require 'httparty'
require 'date'

module Application
  module UseCases
    class ListFacturas
      def initialize(factura_repository:, auditoria_service_url:)
        @factura_repository = factura_repository
        @auditoria_service_url = auditoria_service_url
      end

      def execute(fecha_inicio: nil, fecha_fin: nil)
        if fecha_inicio && fecha_fin
          fecha_inicio_parsed = Date.parse(fecha_inicio.to_s)
          fecha_fin_parsed = Date.parse(fecha_fin.to_s)

          facturas = @factura_repository.find_by_date_range(fecha_inicio_parsed, fecha_fin_parsed)
          details = "Listado de facturas entre #{fecha_inicio} y #{fecha_fin}: #{facturas.count} registros"
        else
          facturas = @factura_repository.find_all
          details = "Listado de todas las facturas: #{facturas.count} registros"
        end

        # Register audit event
        register_audit_event(
          entity_type: 'Factura',
          entity_id: nil,
          action: 'LIST',
          details: details,
          status: 'SUCCESS'
        )

        facturas
      rescue StandardError => e
        # Register audit event for failure
        register_audit_event(
          entity_type: 'Factura',
          entity_id: nil,
          action: 'LIST',
          details: "Error al listar facturas: #{e.message}",
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
