require 'integration_spec_helper'

RSpec.describe 'Auditoria Service API', type: :request do
  describe 'POST /auditoria' do
    context 'with valid data' do
      it 'creates a new audit event' do
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
    before do
      # Create test audit events
      post '/auditoria', {
        entity_type: 'Factura',
        entity_id: 100,
        action: 'CREATE',
        details: 'Factura creada',
        status: 'SUCCESS'
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }

      post '/auditoria', {
        entity_type: 'Factura',
        entity_id: 100,
        action: 'READ',
        details: 'Factura consultada',
        status: 'SUCCESS'
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }

      post '/auditoria', {
        entity_type: 'Factura',
        entity_id: 200,
        action: 'CREATE',
        details: 'Otra factura',
        status: 'SUCCESS'
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }
    end

    it 'returns all events for the specified factura' do
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
      get '/auditoria/999'

      expect(last_response.status).to eq(200)

      json = JSON.parse(last_response.body)
      expect(json['success']).to eq(true)
      expect(json['count']).to eq(0)
      expect(json['data']).to eq([])
    end
  end

  describe 'GET /auditoria/cliente/:cliente_id' do
    before do
      # Create test audit events
      post '/auditoria', {
        entity_type: 'Cliente',
        entity_id: 50,
        action: 'CREATE',
        details: 'Cliente creado',
        status: 'SUCCESS'
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }

      post '/auditoria', {
        entity_type: 'Cliente',
        entity_id: 50,
        action: 'READ',
        details: 'Cliente consultado',
        status: 'SUCCESS'
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }
    end

    it 'returns all events for the specified cliente' do
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
      get '/auditoria/cliente/999'

      expect(last_response.status).to eq(200)

      json = JSON.parse(last_response.body)
      expect(json['success']).to eq(true)
      expect(json['count']).to eq(0)
      expect(json['data']).to eq([])
    end
  end

  describe 'GET /auditoria' do
    before do
      # Create test audit events with different actions and statuses
      post '/auditoria', {
        entity_type: 'Cliente',
        entity_id: 1,
        action: 'CREATE',
        details: 'Cliente creado',
        status: 'SUCCESS'
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }

      post '/auditoria', {
        entity_type: 'Factura',
        entity_id: 2,
        action: 'READ',
        details: 'Factura consultada',
        status: 'SUCCESS'
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }

      post '/auditoria', {
        entity_type: 'Cliente',
        entity_id: 3,
        action: 'CREATE',
        details: 'Error al crear',
        status: 'ERROR'
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }
    end

    context 'without filters' do
      it 'returns all events' do
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
