# Infrastructure Layer - MongoDB implementation of AuditEventRepository (Clean Architecture)

require 'mongo'
require_relative '../../domain/repositories/audit_event_repository'
require_relative '../../domain/entities/audit_event'

module Infrastructure
  module Persistence
    class MongoAuditEventRepository < Domain::Repositories::AuditEventRepository
      def initialize(mongo_client)
        @client = mongo_client
        @collection = @client[:audit_events]
      end

      def save(audit_event)
        document = to_document(audit_event)
        result = @collection.insert_one(document)

        # Update the audit_event with the generated ID
        audit_event_with_id = Domain::Entities::AuditEvent.new(
          id: result.inserted_id,
          entity_type: audit_event.entity_type,
          entity_id: audit_event.entity_id,
          action: audit_event.action,
          details: audit_event.details,
          status: audit_event.status,
          timestamp: audit_event.timestamp,
          created_at: audit_event.created_at
        )

        audit_event_with_id
      end

      def find_by_entity(entity_type:, entity_id:)
        documents = @collection.find(
          entity_type: entity_type,
          entity_id: entity_id
        ).sort(created_at: -1)

        documents.map { |doc| to_entity(doc) }
      end

      def find_by_factura_id(factura_id)
        find_by_entity(entity_type: 'Factura', entity_id: factura_id)
      end

      def find_by_cliente_id(cliente_id)
        find_by_entity(entity_type: 'Cliente', entity_id: cliente_id)
      end

      def find_all(limit: 100)
        documents = @collection.find.sort(created_at: -1).limit(limit)
        documents.map { |doc| to_entity(doc) }
      end

      def find_by_action(action:, limit: 100)
        documents = @collection.find(action: action).sort(created_at: -1).limit(limit)
        documents.map { |doc| to_entity(doc) }
      end

      def find_by_status(status:, limit: 100)
        documents = @collection.find(status: status).sort(created_at: -1).limit(limit)
        documents.map { |doc| to_entity(doc) }
      end

      private

      def to_entity(doc)
        Domain::Entities::AuditEvent.new(
          id: doc['_id'],
          entity_type: doc['entity_type'],
          entity_id: doc['entity_id'],
          action: doc['action'],
          details: doc['details'],
          status: doc['status'],
          timestamp: doc['timestamp'],
          created_at: doc['created_at']
        )
      end

      def to_document(audit_event)
        {
          entity_type: audit_event.entity_type,
          entity_id: audit_event.entity_id,
          action: audit_event.action,
          details: audit_event.details,
          status: audit_event.status,
          timestamp: audit_event.timestamp,
          created_at: audit_event.created_at
        }
      end
    end
  end
end
