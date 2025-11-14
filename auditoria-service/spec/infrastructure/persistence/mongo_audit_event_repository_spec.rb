require 'spec_helper'
require 'mongo'
require_relative '../../../app/infrastructure/persistence/mongo_audit_event_repository'
require_relative '../../../app/domain/repositories/audit_event_repository'

RSpec.describe Infrastructure::Persistence::MongoAuditEventRepository do
  let(:mongo_client) { instance_double(Mongo::Client) }
  let(:collection) { instance_double(Mongo::Collection) }
  let(:repository) { described_class.new(mongo_client) }

  before do
    allow(mongo_client).to receive(:[]).with(:audit_events).and_return(collection)
  end

  describe '#save' do
    it 'saves audit event to MongoDB and returns event with id' do
      audit_event = Domain::Entities::AuditEvent.new(
        entity_type: 'Cliente',
        entity_id: 1,
        action: 'CREATE',
        details: 'Cliente creado',
        status: 'SUCCESS'
      )

      insert_result = instance_double(Mongo::Operation::Insert::Result)
      allow(insert_result).to receive(:inserted_id).and_return('abc123')
      allow(collection).to receive(:insert_one).and_return(insert_result)

      result = repository.save(audit_event)

      expect(result).to be_a(Domain::Entities::AuditEvent)
      expect(result.id).to eq('abc123')
      expect(result.entity_type).to eq('Cliente')
      expect(result.entity_id).to eq(1)
      expect(result.action).to eq('CREATE')
      expect(result.status).to eq('SUCCESS')

      expect(collection).to have_received(:insert_one).with(hash_including(
        entity_type: 'Cliente',
        entity_id: 1,
        action: 'CREATE',
        details: 'Cliente creado',
        status: 'SUCCESS'
      ))
    end
  end

  describe '#find_by_entity' do
    it 'finds events by entity_type and entity_id' do
      documents = [
        {
          '_id' => 'event1',
          'entity_type' => 'Cliente',
          'entity_id' => 1,
          'action' => 'CREATE',
          'details' => 'Cliente creado',
          'status' => 'SUCCESS',
          'timestamp' => Time.now.utc.iso8601,
          'created_at' => Time.now.utc
        }
      ]

      query_result = instance_double(Mongo::Collection::View)
      allow(collection).to receive(:find).with(entity_type: 'Cliente', entity_id: 1).and_return(query_result)
      allow(query_result).to receive(:sort).with(created_at: -1).and_return(documents)

      result = repository.find_by_entity(entity_type: 'Cliente', entity_id: 1)

      expect(result).to be_an(Array)
      expect(result.size).to eq(1)
      expect(result.first).to be_a(Domain::Entities::AuditEvent)
      expect(result.first.entity_type).to eq('Cliente')
      expect(result.first.entity_id).to eq(1)
    end
  end

  describe '#find_by_factura_id' do
    it 'delegates to find_by_entity with Factura entity_type' do
      expect(repository).to receive(:find_by_entity).with(entity_type: 'Factura', entity_id: 100)

      repository.find_by_factura_id(100)
    end
  end

  describe '#find_by_cliente_id' do
    it 'delegates to find_by_entity with Cliente entity_type' do
      expect(repository).to receive(:find_by_entity).with(entity_type: 'Cliente', entity_id: 50)

      repository.find_by_cliente_id(50)
    end
  end

  describe '#find_all' do
    it 'returns all events with specified limit' do
      documents = [
        {
          '_id' => 'event1',
          'entity_type' => 'Cliente',
          'entity_id' => 1,
          'action' => 'CREATE',
          'details' => 'Cliente creado',
          'status' => 'SUCCESS',
          'timestamp' => Time.now.utc.iso8601,
          'created_at' => Time.now.utc
        }
      ]

      query_result = instance_double(Mongo::Collection::View)
      sorted_result = instance_double(Mongo::Collection::View)

      allow(collection).to receive(:find).and_return(query_result)
      allow(query_result).to receive(:sort).with(created_at: -1).and_return(sorted_result)
      allow(sorted_result).to receive(:limit).with(100).and_return(documents)

      result = repository.find_all(limit: 100)

      expect(result).to be_an(Array)
      expect(result.size).to eq(1)
      expect(result.first).to be_a(Domain::Entities::AuditEvent)
    end
  end

  describe '#find_by_action' do
    it 'finds events by action with specified limit' do
      documents = [
        {
          '_id' => 'event1',
          'entity_type' => 'Cliente',
          'entity_id' => 1,
          'action' => 'CREATE',
          'details' => 'Cliente creado',
          'status' => 'SUCCESS',
          'timestamp' => Time.now.utc.iso8601,
          'created_at' => Time.now.utc
        }
      ]

      query_result = instance_double(Mongo::Collection::View)
      sorted_result = instance_double(Mongo::Collection::View)

      allow(collection).to receive(:find).with(action: 'CREATE').and_return(query_result)
      allow(query_result).to receive(:sort).with(created_at: -1).and_return(sorted_result)
      allow(sorted_result).to receive(:limit).with(50).and_return(documents)

      result = repository.find_by_action(action: 'CREATE', limit: 50)

      expect(result).to be_an(Array)
      expect(result.size).to eq(1)
      expect(result.first.action).to eq('CREATE')
    end
  end

  describe '#find_by_status' do
    it 'finds events by status with specified limit' do
      documents = [
        {
          '_id' => 'event1',
          'entity_type' => 'Cliente',
          'entity_id' => 1,
          'action' => 'CREATE',
          'details' => 'Error al crear',
          'status' => 'ERROR',
          'timestamp' => Time.now.utc.iso8601,
          'created_at' => Time.now.utc
        }
      ]

      query_result = instance_double(Mongo::Collection::View)
      sorted_result = instance_double(Mongo::Collection::View)

      allow(collection).to receive(:find).with(status: 'ERROR').and_return(query_result)
      allow(query_result).to receive(:sort).with(created_at: -1).and_return(sorted_result)
      allow(sorted_result).to receive(:limit).with(100).and_return(documents)

      result = repository.find_by_status(status: 'ERROR', limit: 100)

      expect(result).to be_an(Array)
      expect(result.size).to eq(1)
      expect(result.first.status).to eq('ERROR')
    end
  end
end
