# Domain Layer - Factura Repository Interface (Clean Architecture)

module Domain
  module Repositories
    class FacturaRepository
      def save(factura)
        raise NotImplementedError, 'Subclasses must implement save method'
      end

      def find_by_id(id)
        raise NotImplementedError, 'Subclasses must implement find_by_id method'
      end

      def find_all
        raise NotImplementedError, 'Subclasses must implement find_all method'
      end

      def find_by_date_range(fecha_inicio, fecha_fin)
        raise NotImplementedError, 'Subclasses must implement find_by_date_range method'
      end

      def find_by_cliente_id(cliente_id)
        raise NotImplementedError, 'Subclasses must implement find_by_cliente_id method'
      end

      def update(id, attributes)
        raise NotImplementedError, 'Subclasses must implement update method'
      end

      def delete(id)
        raise NotImplementedError, 'Subclasses must implement delete method'
      end
    end
  end
end
