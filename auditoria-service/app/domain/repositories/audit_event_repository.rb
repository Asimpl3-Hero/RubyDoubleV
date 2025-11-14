# Domain Layer - AuditEvent Repository Interface (Clean Architecture)
# This defines the contract for data persistence without implementation details

module Domain
  module Repositories
    class AuditEventRepository
      def save(audit_event)
        raise NotImplementedError, 'Subclasses must implement save method'
      end

      def find_by_entity(entity_type:, entity_id:)
        raise NotImplementedError, 'Subclasses must implement find_by_entity method'
      end

      def find_by_factura_id(factura_id)
        raise NotImplementedError, 'Subclasses must implement find_by_factura_id method'
      end

      def find_by_cliente_id(cliente_id)
        raise NotImplementedError, 'Subclasses must implement find_by_cliente_id method'
      end

      def find_all(limit:)
        raise NotImplementedError, 'Subclasses must implement find_all method'
      end

      def find_by_action(action:, limit:)
        raise NotImplementedError, 'Subclasses must implement find_by_action method'
      end

      def find_by_status(status:, limit:)
        raise NotImplementedError, 'Subclasses must implement find_by_status method'
      end
    end
  end
end
