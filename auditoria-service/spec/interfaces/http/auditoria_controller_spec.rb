require 'integration_spec_helper'

RSpec.describe 'Auditoria Service API', type: :request do
  let(:mock_repository) { instance_double(Infrastructure::Persistence::MongoAuditEventRepository) }
  let(:mock_mongo_client) { instance_double(Mongo::Client) }

  before do
    # Mock MongoDB client and repository
    allow(Mongo::Client).to receive(:new).and_return(mock_mongo_client)
    allow(Infrastructure::Persistence::MongoAuditEventRepository).to receive(:new).and_return(mock_repository)

    # Mock MongoDB collection for cleanup operations
    mock_collection = double('Collection')
    allow(mock_collection).to receive(:delete_many)
    allow(mock_mongo_client).to receive(:[]).with(:audit_events).and_return(mock_collection)
    allow(mock_mongo_client).to receive(:close)
  end
  describe 'POST /auditoria' do
    context 'with valid data' do
      it 'creates a new audit event' do
        # Mock the repository save operation
        saved_event = Domain::Entities::AuditEvent.new(
          id: 'mock_id_123',
          entity_type: 'Cliente',
          entity_id: 1,
          action: 'CREATE',
          details: 'Cliente creado: Empresa ABC',
          status: 'SUCCESS'
        )
        allow(mock_repository).to receive(:save).and_return(saved_event)

        post '/auditoria', {
          entity_type: 'Cliente',
          entity_id: 1,
          action: 'CREATE',
          details: 'Cliente creado: Empresa ABC',
          status: 'SUCCESS',
          timestamp: Time.now.utc.iso8601
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(201)

        json = JSON.parse(last_response.body)
        expect(json['success']).to eq(true)
        expect(json['message']).to eq('Evento de auditoría registrado')
        expect(json['data']['entity_type']).to eq('Cliente')
        expect(json['data']['entity_id']).to eq(1)
        expect(json['data']['action']).to eq('CREATE')
        expect(json['data']['status']).to eq('SUCCESS')
        expect(json['data']['id']).not_to be_nil
      end

      it 'creates audit event with nil entity_id' do
        # Mock the repository save operation
        saved_event = Domain::Entities::AuditEvent.new(
          id: 'mock_id_456',
          entity_type: 'Cliente',
          entity_id: nil,
          action: 'LIST',
          details: 'Listado de clientes',
          status: 'SUCCESS'
        )
        allow(mock_repository).to receive(:save).and_return(saved_event)

        post '/auditoria', {
          entity_type: 'Cliente',
          entity_id: nil,
          action: 'LIST',
          details: 'Listado de clientes',
          status: 'SUCCESS'
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(201)

        json = JSON.parse(last_response.body)
        expect(json['success']).to eq(true)
        expect(json['data']['entity_id']).to be_nil
      end
    end

    context 'with invalid data' do
      it 'returns 400 when entity_type is missing' do
        post '/auditoria', {
          entity_id: 1,
          action: 'CREATE',
          details: 'Test',
          status: 'SUCCESS'
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(400)

        json = JSON.parse(last_response.body)
        expect(json['success']).to eq(false)
        expect(json['error']).to include('entity_type es requerido')
      end

      it 'returns 400 when status is invalid' do
        post '/auditoria', {
          entity_type: 'Cliente',
          entity_id: 1,
          action: 'CREATE',
          details: 'Test',
          status: 'INVALID_STATUS'
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(400)

        json = JSON.parse(last_response.body)
        expect(json['success']).to eq(false)
        expect(json['error']).to include('status debe ser SUCCESS o ERROR')
      end
    end
  end

  describe 'GET /auditoria/:factura_id' do
    it 'returns all events for the specified factura' do
      # Mock events for factura 100
      events = [
        Domain::Entities::AuditEvent.new(
          id: '1',
          entity_type: 'Factura',
          entity_id: 100,
          action: 'CREATE',
          details: 'Factura creada',
          status: 'SUCCESS'
        ),
        Domain::Entities::AuditEvent.new(
          id: '2',
          entity_type: 'Factura',
          entity_id: 100,
          action: 'READ',
          details: 'Factura consultada',
          status: 'SUCCESS'
        )
      ]
      allow(mock_repository).to receive(:find_by_factura_id).with(100).and_return(events)

      get '/auditoria/100'

      expect(last_response.status).to eq(200)

      json = JSON.parse(last_response.body)
      expect(json['success']).to eq(true)
      expect(json['count']).to eq(2)
      expect(json['data'].size).to eq(2)
      expect(json['data'].all? { |e| e['entity_id'] == 100 }).to be true
      expect(json['data'].all? { |e| e['entity_type'] == 'Factura' }).to be true
    end

    it 'returns empty array when no events exist for factura' do
      allow(mock_repository).to receive(:find_by_factura_id).with(999).and_return([])

      get '/auditoria/999'

      expect(last_response.status).to eq(200)

      json = JSON.parse(last_response.body)
      expect(json['success']).to eq(true)
      expect(json['count']).to eq(0)
      expect(json['data']).to eq([])
    end
  end

  describe 'GET /auditoria/cliente/:cliente_id' do
    it 'returns all events for the specified cliente' do
      # Mock events for cliente 50
      events = [
        Domain::Entities::AuditEvent.new(
          id: '1',
          entity_type: 'Cliente',
          entity_id: 50,
          action: 'CREATE',
          details: 'Cliente creado',
          status: 'SUCCESS'
        ),
        Domain::Entities::AuditEvent.new(
          id: '2',
          entity_type: 'Cliente',
          entity_id: 50,
          action: 'READ',
          details: 'Cliente consultado',
          status: 'SUCCESS'
        )
      ]
      allow(mock_repository).to receive(:find_by_cliente_id).with(50).and_return(events)

      get '/auditoria/cliente/50'

      expect(last_response.status).to eq(200)

      json = JSON.parse(last_response.body)
      expect(json['success']).to eq(true)
      expect(json['count']).to eq(2)
      expect(json['data'].size).to eq(2)
      expect(json['data'].all? { |e| e['entity_id'] == 50 }).to be true
      expect(json['data'].all? { |e| e['entity_type'] == 'Cliente' }).to be true
    end

    it 'returns empty array when no events exist for cliente' do
      allow(mock_repository).to receive(:find_by_cliente_id).with(999).and_return([])

      get '/auditoria/cliente/999'

      expect(last_response.status).to eq(200)

      json = JSON.parse(last_response.body)
      expect(json['success']).to eq(true)
      expect(json['count']).to eq(0)
      expect(json['data']).to eq([])
    end
  end

  describe 'GET /auditoria' do
    context 'without filters' do
      it 'returns all events' do
        events = [
          Domain::Entities::AuditEvent.new(
            id: '1',
            entity_type: 'Cliente',
            entity_id: 1,
            action: 'CREATE',
            details: 'Cliente creado',
            status: 'SUCCESS'
          ),
          Domain::Entities::AuditEvent.new(
            id: '2',
            entity_type: 'Factura',
            entity_id: 2,
            action: 'READ',
            details: 'Factura consultada',
            status: 'SUCCESS'
          ),
          Domain::Entities::AuditEvent.new(
            id: '3',
            entity_type: 'Cliente',
            entity_id: 3,
            action: 'CREATE',
            details: 'Error al crear',
            status: 'ERROR'
          )
        ]
        allow(mock_repository).to receive(:find_all).with(limit: 100).and_return(events)

        get '/auditoria'

        expect(last_response.status).to eq(200)

        json = JSON.parse(last_response.body)
        expect(json['success']).to eq(true)
        expect(json['count']).to eq(3)
        expect(json['data'].size).to eq(3)
      end
    end

    context 'with action filter' do
      it 'returns only events with specified action' do
        events = [
          Domain::Entities::AuditEvent.new(
            id: '1',
            entity_type: 'Cliente',
            entity_id: 1,
            action: 'CREATE',
            details: 'Cliente creado',
            status: 'SUCCESS'
          ),
          Domain::Entities::AuditEvent.new(
            id: '3',
            entity_type: 'Cliente',
            entity_id: 3,
            action: 'CREATE',
            details: 'Error al crear',
            status: 'ERROR'
          )
        ]
        allow(mock_repository).to receive(:find_by_action).with(action: 'CREATE', limit: 100).and_return(events)

        get '/auditoria?action=CREATE'

        expect(last_response.status).to eq(200)

        json = JSON.parse(last_response.body)
        expect(json['success']).to eq(true)
        expect(json['count']).to eq(2)
        expect(json['data'].all? { |e| e['action'] == 'CREATE' }).to be true
      end
    end

    context 'with status filter' do
      it 'returns only events with specified status' do
        events = [
          Domain::Entities::AuditEvent.new(
            id: '3',
            entity_type: 'Cliente',
            entity_id: 3,
            action: 'CREATE',
            details: 'Error al crear',
            status: 'ERROR'
          )
        ]
        allow(mock_repository).to receive(:find_by_status).with(status: 'ERROR', limit: 100).and_return(events)

        get '/auditoria?status=ERROR'

        expect(last_response.status).to eq(200)

        json = JSON.parse(last_response.body)
        expect(json['success']).to eq(true)
        expect(json['count']).to eq(1)
        expect(json['data'].all? { |e| e['status'] == 'ERROR' }).to be true
      end
    end

    context 'with limit parameter' do
      it 'returns limited number of events' do
        events = [
          Domain::Entities::AuditEvent.new(
            id: '1',
            entity_type: 'Cliente',
            entity_id: 1,
            action: 'CREATE',
            details: 'Cliente creado',
            status: 'SUCCESS'
          ),
          Domain::Entities::AuditEvent.new(
            id: '2',
            entity_type: 'Factura',
            entity_id: 2,
            action: 'READ',
            details: 'Factura consultada',
            status: 'SUCCESS'
          )
        ]
        allow(mock_repository).to receive(:find_all).with(limit: 2).and_return(events)

        get '/auditoria?limit=2'

        expect(last_response.status).to eq(200)

        json = JSON.parse(last_response.body)
        expect(json['success']).to eq(true)
        expect(json['data'].size).to be <= 2
      end
    end
  end

  describe 'GET /health' do
    it 'returns health check response' do
      get '/health'

      expect(last_response.status).to eq(200)

      json = JSON.parse(last_response.body)
      expect(json['success']).to eq(true)
      expect(json['service']).to eq('auditoria-service')
      expect(json['status']).to eq('running')
      expect(json['timestamp']).not_to be_nil
    end
  end
end
