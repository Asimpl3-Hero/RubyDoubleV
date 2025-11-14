# Infrastructure Layer - ActiveRecord implementation of FacturaRepository

require_relative '../../domain/repositories/factura_repository'
require_relative '../../domain/entities/factura'
require_relative '../../models/factura_model'

module Infrastructure
  module Persistence
    class ActiveRecordFacturaRepository < Domain::Repositories::FacturaRepository
      def save(factura)
        factura_model = FacturaModel.create!(
          cliente_id: factura.cliente_id,
          numero_factura: factura.numero_factura,
          fecha_emision: factura.fecha_emision,
          monto: factura.monto,
          estado: factura.estado,
          items: factura.items
        )

        to_entity(factura_model)
      end

      def find_by_id(id)
        factura_model = FacturaModel.find_by(id: id)
        return nil unless factura_model

        to_entity(factura_model)
      end

      def find_all
        FacturaModel.all.order(fecha_emision: :desc).map { |model| to_entity(model) }
      end

      def find_by_date_range(fecha_inicio, fecha_fin)
        FacturaModel
          .where('fecha_emision >= ? AND fecha_emision <= ?', fecha_inicio, fecha_fin)
          .order(fecha_emision: :desc)
          .map { |model| to_entity(model) }
      end

      def find_by_cliente_id(cliente_id)
        FacturaModel
          .where(cliente_id: cliente_id)
          .order(fecha_emision: :desc)
          .map { |model| to_entity(model) }
      end

      def update(id, attributes)
        factura_model = FacturaModel.find(id)
        factura_model.update!(attributes)
        to_entity(factura_model)
      end

      def delete(id)
        factura_model = FacturaModel.find(id)
        factura_model.destroy
      end

      private

      def to_entity(model)
        Domain::Entities::Factura.new(
          id: model.id,
          cliente_id: model.cliente_id,
          numero_factura: model.numero_factura,
          fecha_emision: model.fecha_emision,
          monto: model.monto.to_f,
          estado: model.estado,
          items: model.items || [],
          created_at: model.created_at,
          updated_at: model.updated_at
        )
      end
    end
  end
end
