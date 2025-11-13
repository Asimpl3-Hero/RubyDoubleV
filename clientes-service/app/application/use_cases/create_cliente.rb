# Application Layer - Use Case (Clean Architecture)
# Orchestrates business logic for creating a cliente

require_relative '../../domain/entities/cliente'
require 'httparty'

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
          entity_type: 'Cliente',
          entity_id: saved_cliente.id,
          action: 'CREATE',
          details: "Cliente creado: #{saved_cliente.nombre}",
          status: 'SUCCESS'
        )

        saved_cliente
      rescue StandardError => e
        # Register audit event for failure
        register_audit_event(
          entity_type: 'Cliente',
          entity_id: nil,
          action: 'CREATE',
          details: "Error al crear cliente: #{e.message}",
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
