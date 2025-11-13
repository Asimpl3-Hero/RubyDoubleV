# Infrastructure Layer - ActiveRecord implementation of ClienteRepository (Clean Architecture)

require_relative '../../domain/repositories/cliente_repository'
require_relative '../../domain/entities/cliente'
require_relative '../../models/cliente_model'

module Infrastructure
  module Persistence
    class ActiveRecordClienteRepository < Domain::Repositories::ClienteRepository
      def save(cliente)
        cliente_model = ClienteModel.create!(
          nombre: cliente.nombre,
          identificacion: cliente.identificacion,
          correo: cliente.correo,
          direccion: cliente.direccion
        )

        to_entity(cliente_model)
      end

      def find_by_id(id)
        cliente_model = ClienteModel.find_by(id: id)
        return nil unless cliente_model

        to_entity(cliente_model)
      end

      def find_all
        ClienteModel.all.map { |model| to_entity(model) }
      end

      def find_by_identificacion(identificacion)
        cliente_model = ClienteModel.find_by(identificacion: identificacion)
        return nil unless cliente_model

        to_entity(cliente_model)
      end

      def update(id, attributes)
        cliente_model = ClienteModel.find(id)
        cliente_model.update!(attributes)
        to_entity(cliente_model)
      end

      def delete(id)
        cliente_model = ClienteModel.find(id)
        cliente_model.destroy
      end

      private

      def to_entity(model)
        Domain::Entities::Cliente.new(
          id: model.id,
          nombre: model.nombre,
          identificacion: model.identificacion,
          correo: model.correo,
          direccion: model.direccion,
          created_at: model.created_at,
          updated_at: model.updated_at
        )
      end
    end
  end
end
