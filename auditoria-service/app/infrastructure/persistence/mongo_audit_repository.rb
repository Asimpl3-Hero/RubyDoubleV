# Infrastructure Layer - MongoDB implementation for audit events

require 'mongo'
require_relative '../../models/audit_event'

module Infrastructure
  module Persistence
    class MongoAuditRepository
      def initialize(mongo_client)
        @client = mongo_client
        @collection = @client[:audit_events]
      end

      def save(audit_event)
        result = @collection.insert_one(audit_event.to_document)
        audit_event.id = result.inserted_id
        audit_event
      end

      def find_by_entity(entity_type:, entity_id:)
        documents = @collection.find(
          entity_type: entity_type,
          entity_id: entity_id
        ).sort(created_at: -1)

        documents.map { |doc| AuditEvent.from_document(doc) }
      end

      def find_by_factura_id(factura_id)
        find_by_entity(entity_type: 'Factura', entity_id: factura_id)
      end

      def find_by_cliente_id(cliente_id)
        find_by_entity(entity_type: 'Cliente', entity_id: cliente_id)
      end

      def find_all(limit: 100)
        documents = @collection.find.sort(created_at: -1).limit(limit)
        documents.map { |doc| AuditEvent.from_document(doc) }
      end

      def find_by_action(action:, limit: 100)
        documents = @collection.find(action: action).sort(created_at: -1).limit(limit)
        documents.map { |doc| AuditEvent.from_document(doc) }
      end

      def find_by_status(status:, limit: 100)
        documents = @collection.find(status: status).sort(created_at: -1).limit(limit)
        documents.map { |doc| AuditEvent.from_document(doc) }
      end
    end
  end
end
