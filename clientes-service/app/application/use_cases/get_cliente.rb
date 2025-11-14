# Application Layer - Use Case for retrieving a cliente

require 'httparty'

module Application
  module UseCases
    class GetCliente
      def initialize(cliente_repository:, auditoria_service_url:)
        @cliente_repository = cliente_repository
        @auditoria_service_url = auditoria_service_url
      end

      def execute(id:)
        cliente = @cliente_repository.find_by_id(id)

        raise StandardError, "Cliente con ID #{id} no encontrado" unless cliente

        # Register audit event
        register_audit_event(
          entity_type: 'cliente',
          entity_id: cliente.id,
          action: 'READ',
          details: "Cliente consultado: #{cliente.nombre}",
          status: 'SUCCESS'
        )

        cliente
      rescue StandardError => e
        # Register audit event for failure
        register_audit_event(
          entity_type: 'cliente',
          entity_id: id,
          action: 'READ',
          details: "Error al consultar cliente: #{e.message}",
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
