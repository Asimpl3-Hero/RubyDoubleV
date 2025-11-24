# Application Layer - Use Case for listing facturas with optional date filter

require_relative '../../../../shared/messaging/audit_publisher' unless defined?(Messaging::AuditPublisher)
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
          entity_type: 'factura',
          entity_id: nil,
          action: 'LIST',
          details: details,
          status: 'SUCCESS'
        )

        facturas
      rescue StandardError => e
        # Register audit event for failure
        register_audit_event(
          entity_type: 'factura',
          entity_id: nil,
          action: 'LIST',
          details: "Error al listar facturas: #{e.message}",
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
