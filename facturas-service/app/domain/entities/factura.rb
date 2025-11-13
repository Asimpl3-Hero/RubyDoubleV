# Domain Layer - Factura Entity (Clean Architecture)

module Domain
  module Entities
    class Factura
      attr_reader :id, :cliente_id, :numero_factura, :fecha_emision, :monto, :estado, :items, :created_at, :updated_at

      def initialize(id: nil, cliente_id:, numero_factura: nil, fecha_emision:, monto:, estado: 'EMITIDA', items: [], created_at: nil, updated_at: nil)
        @id = id
        @cliente_id = cliente_id
        @numero_factura = numero_factura || generate_numero_factura
        @fecha_emision = fecha_emision
        @monto = monto
        @estado = estado
        @items = items
        @created_at = created_at
        @updated_at = updated_at

        validate!
      end

      def to_h
        {
          id: @id,
          cliente_id: @cliente_id,
          numero_factura: @numero_factura,
          fecha_emision: @fecha_emision,
          monto: @monto,
          estado: @estado,
          items: @items,
          created_at: @created_at,
          updated_at: @updated_at
        }
      end

      private

      def validate!
        raise ArgumentError, 'Cliente ID es requerido' if @cliente_id.nil?
        raise ArgumentError, 'Fecha de emisión es requerida' if @fecha_emision.nil?
        raise ArgumentError, 'Monto debe ser mayor a 0' unless @monto.is_a?(Numeric) && @monto > 0
        raise ArgumentError, 'Fecha de emisión inválida' unless valid_date?(@fecha_emision)
      end

      def valid_date?(date)
        return false if date.nil?
        date_obj = date.is_a?(String) ? Date.parse(date) : date
        date_obj <= Date.today
      rescue ArgumentError
        false
      end

      def generate_numero_factura
        "F-#{Time.now.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
      end
    end
  end
end
