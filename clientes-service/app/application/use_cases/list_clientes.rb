# Application Layer - Use Case for listing all clientes

require 'httparty'

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
