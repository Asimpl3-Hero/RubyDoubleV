require_relative '../integration_spec_helper'

RSpec.describe 'Integration: Clientes → Auditoría', type: :integration do
  let(:auditoria_url) { ENV['AUDITORIA_SERVICE_URL'] }

  describe 'POST /clientes' do
    context 'when creating a cliente successfully' do
      let(:cliente_params) do
        {
          nombre: 'Empresa Test S.A.',
          identificacion: '900123456',
          correo: 'test@empresa.com',
          direccion: 'Calle 123 #45-67, Bogotá'
        }
      end

      it 'creates cliente and registers audit event' do
        # Mock Auditoría service response
        audit_stub = stub_request(:post, "#{auditoria_url}/auditoria")
          .with(
            body: hash_including(
              entity_type: 'cliente',
              action: 'CREATE',
              status: 'SUCCESS'
            )
          )
          .to_return(
            status: 201,
            body: { success: true, message: 'Evento registrado' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Create cliente
        post '/clientes', cliente_params.to_json, { 'CONTENT_TYPE' => 'application/json' }

        # Verify response
        expect(last_response.status).to eq(201)
        response_body = JSON.parse(last_response.body, symbolize_names: true)

        expect(response_body[:success]).to be true
        expect(response_body[:message]).to eq('Cliente creado exitosamente')
        expect(response_body[:data][:nombre]).to eq('Empresa Test S.A.')
        expect(response_body[:data][:identificacion]).to eq('900123456')
        expect(response_body[:data][:id]).not_to be_nil

        # Verify audit event was sent
        expect(audit_stub).to have_been_requested.once
      end

      it 'sends correct audit payload to Auditoría service' do
        audit_request = nil

        stub_request(:post, "#{auditoria_url}/auditoria")
          .to_return do |request|
            audit_request = JSON.parse(request.body, symbolize_names: true)
            { status: 201, body: { success: true }.to_json }
          end

        post '/clientes', cliente_params.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(audit_request).not_to be_nil
        expect(audit_request[:entity_type]).to eq('cliente')
        expect(audit_request[:action]).to eq('CREATE')
        expect(audit_request[:status]).to eq('SUCCESS')
        expect(audit_request[:entity_id]).not_to be_nil
        expect(audit_request[:metadata]).to be_a(Hash)
        expect(audit_request[:metadata][:nombre]).to eq('Empresa Test S.A.')
      end
    end

    context 'when cliente creation fails' do
      let(:invalid_params) do
        {
          nombre: '',
          identificacion: '900123456',
          correo: 'test@empresa.com',
          direccion: 'Calle 123'
        }
      end

      it 'registers error event in Auditoría' do
        audit_stub = stub_request(:post, "#{auditoria_url}/auditoria")
          .with(
            body: hash_including(
              entity_type: 'cliente',
              action: 'CREATE',
              status: 'ERROR'
            )
          )
          .to_return(status: 201, body: { success: true }.to_json)

        post '/clientes', invalid_params.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(422)
        expect(audit_stub).to have_been_requested.once
      end
    end

    context 'when Auditoría service is unavailable' do
      let(:cliente_params) do
        {
          nombre: 'Empresa Test S.A.',
          identificacion: '900123456',
          correo: 'test@empresa.com',
          direccion: 'Calle 123 #45-67'
        }
      end

      it 'still creates cliente even if audit fails' do
        # Mock Auditoría service failure
        stub_request(:post, "#{auditoria_url}/auditoria")
          .to_timeout

        post '/clientes', cliente_params.to_json, { 'CONTENT_TYPE' => 'application/json' }

        # Cliente should still be created
        expect(last_response.status).to eq(201)
        response_body = JSON.parse(last_response.body, symbolize_names: true)
        expect(response_body[:success]).to be true

        # Verify cliente exists in database
        cliente = ClienteModel.last
        expect(cliente.nombre).to eq('Empresa Test S.A.')
      end
    end
  end

  describe 'GET /clientes/:id' do
    let!(:cliente) do
      ClienteModel.create!(
        nombre: 'Empresa Consulta S.A.',
        identificacion: '900654321',
        correo: 'consulta@empresa.com',
        direccion: 'Avenida 456'
      )
    end

    it 'retrieves cliente and registers audit event' do
      audit_stub = stub_request(:post, "#{auditoria_url}/auditoria")
        .with(
          body: hash_including(
            entity_type: 'cliente',
            action: 'READ',
            status: 'SUCCESS',
            entity_id: cliente.id
          )
        )
        .to_return(status: 201, body: { success: true }.to_json)

      get "/clientes/#{cliente.id}"

      expect(last_response.status).to eq(200)
      response_body = JSON.parse(last_response.body, symbolize_names: true)

      expect(response_body[:success]).to be true
      expect(response_body[:data][:nombre]).to eq('Empresa Consulta S.A.')
      expect(audit_stub).to have_been_requested.once
    end
  end

  describe 'GET /clientes' do
    before do
      ClienteModel.create!(
        nombre: 'Cliente 1',
        identificacion: '900111111',
        correo: 'cliente1@test.com',
        direccion: 'Dir 1'
      )
      ClienteModel.create!(
        nombre: 'Cliente 2',
        identificacion: '900222222',
        correo: 'cliente2@test.com',
        direccion: 'Dir 2'
      )
    end

    it 'lists clientes and registers audit event' do
      audit_stub = stub_request(:post, "#{auditoria_url}/auditoria")
        .with(
          body: hash_including(
            entity_type: 'cliente',
            action: 'LIST',
            status: 'SUCCESS'
          )
        )
        .to_return(status: 201, body: { success: true }.to_json)

      get '/clientes'

      expect(last_response.status).to eq(200)
      response_body = JSON.parse(last_response.body, symbolize_names: true)

      expect(response_body[:success]).to be true
      expect(response_body[:data]).to be_an(Array)
      expect(response_body[:data].length).to eq(2)
      expect(audit_stub).to have_been_requested.once
    end
  end
end
