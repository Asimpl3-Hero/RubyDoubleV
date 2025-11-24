# Domain Layer - Factura Entity (Clean Architecture)

module Domain
  module Entities
    class Factura
      # IVA percentages allowed in Colombia
      VALID_IVA_PERCENTAGES = [0, 5, 19].freeze

      attr_reader :id, :cliente_id, :numero_factura, :fecha_emision, :subtotal,
                  :iva_porcentaje, :iva_valor, :total, :estado, :items, :created_at, :updated_at

      def initialize(id: nil, cliente_id:, numero_factura: nil, fecha_emision:,
                     subtotal: nil, iva_porcentaje: 19, estado: 'EMITIDA', items: [],
                     created_at: nil, updated_at: nil,
                     # Backward compatibility
                     monto: nil)
        @id = id
        @cliente_id = cliente_id
        @numero_factura = numero_factura || generate_numero_factura
        @fecha_emision = fecha_emision

        # Handle backward compatibility: if monto is provided but not subtotal, use monto as subtotal
        @subtotal = subtotal || monto
        raise ArgumentError, 'Se requiere subtotal o monto' unless @subtotal

        @iva_porcentaje = iva_porcentaje.to_f

        # Calculate IVA and total
        @iva_valor = calculate_iva(@subtotal, @iva_porcentaje)
        @total = @subtotal + @iva_valor

        @estado = estado
        @items = items
        @created_at = created_at
        @updated_at = updated_at

        validate!
      end

      # Alias for backward compatibility
      def monto
        @total
      end

      def to_h
        {
          id: @id,
          cliente_id: @cliente_id,
          numero_factura: @numero_factura,
          fecha_emision: @fecha_emision,
          subtotal: @subtotal,
          iva_porcentaje: @iva_porcentaje,
          iva_valor: @iva_valor,
          total: @total,
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
        raise ArgumentError, 'Subtotal debe ser mayor a 0' unless @subtotal.is_a?(Numeric) && @subtotal > 0
        raise ArgumentError, 'Fecha de emisión inválida' unless valid_date?(@fecha_emision)
        raise ArgumentError, "IVA porcentaje debe ser #{VALID_IVA_PERCENTAGES.join(', ')}%" unless VALID_IVA_PERCENTAGES.include?(@iva_porcentaje)
      end

      def calculate_iva(subtotal, porcentaje)
        (subtotal * porcentaje / 100).round(2)
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
