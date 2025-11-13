# Domain Layer - Cliente Repository Interface (Clean Architecture)
# This defines the contract for data persistence without implementation details

module Domain
  module Repositories
    class ClienteRepository
      def save(cliente)
        raise NotImplementedError, 'Subclasses must implement save method'
      end

      def find_by_id(id)
        raise NotImplementedError, 'Subclasses must implement find_by_id method'
      end

      def find_all
        raise NotImplementedError, 'Subclasses must implement find_all method'
      end

      def find_by_identificacion(identificacion)
        raise NotImplementedError, 'Subclasses must implement find_by_identificacion method'
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
