require_relative '../../integration_spec_helper'

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

        # Verify audit event was published to RabbitMQ mock
        expect(Messaging::AuditPublisherMock.events_count).to eq(1)
        event = Messaging::AuditPublisherMock.last_event
        expect(event[:entity_type]).to eq('cliente')
        expect(event[:action]).to eq('CREATE')
        expect(event[:status]).to eq('SUCCESS')
      end

      it 'sends correct audit payload to message queue' do
        post '/clientes', cliente_params.to_json, { 'CONTENT_TYPE' => 'application/json' }

        event = Messaging::AuditPublisherMock.last_event
        expect(event).not_to be_nil
        expect(event[:entity_type]).to eq('cliente')
        expect(event[:action]).to eq('CREATE')
        expect(event[:status]).to eq('SUCCESS')
        expect(event[:entity_id]).not_to be_nil
        expect(event[:details]).to be_a(String)
        expect(event[:details]).to include('Cliente creado')
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

      it 'registers error event in message queue' do
        post '/clientes', invalid_params.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(400)

        # Verify error event was published
        expect(Messaging::AuditPublisherMock.events_count).to eq(1)
        event = Messaging::AuditPublisherMock.last_event
        expect(event[:entity_type]).to eq('cliente')
        expect(event[:action]).to eq('CREATE')
        expect(event[:status]).to eq('ERROR')
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

      it 'creates cliente and publishes to message queue' do
        post '/clientes', cliente_params.to_json, { 'CONTENT_TYPE' => 'application/json' }

        # Cliente should be created
        expect(last_response.status).to eq(201)
        response_body = JSON.parse(last_response.body, symbolize_names: true)
        expect(response_body[:success]).to be true

        # Verify cliente exists in database
        cliente = ClienteModel.last
        expect(cliente.nombre).to eq('Empresa Test S.A.')

        # Verify audit event was published
        expect(Messaging::AuditPublisherMock.events_count).to eq(1)
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
      get "/clientes/#{cliente.id}"

      expect(last_response.status).to eq(200)
      response_body = JSON.parse(last_response.body, symbolize_names: true)

      expect(response_body[:success]).to be true
      expect(response_body[:data][:nombre]).to eq('Empresa Consulta S.A.')

      # Verify audit event was published
      expect(Messaging::AuditPublisherMock.events_count).to eq(1)
      event = Messaging::AuditPublisherMock.last_event
      expect(event[:entity_type]).to eq('cliente')
      expect(event[:action]).to eq('READ')
      expect(event[:status]).to eq('SUCCESS')
      expect(event[:entity_id]).to eq(cliente.id)
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
      get '/clientes'

      expect(last_response.status).to eq(200)
      response_body = JSON.parse(last_response.body, symbolize_names: true)

      expect(response_body[:success]).to be true
      expect(response_body[:data]).to be_an(Array)
      expect(response_body[:data].length).to eq(2)

      # Verify audit event was published
      expect(Messaging::AuditPublisherMock.events_count).to eq(1)
      event = Messaging::AuditPublisherMock.last_event
      expect(event[:entity_type]).to eq('cliente')
      expect(event[:action]).to eq('LIST')
      expect(event[:status]).to eq('SUCCESS')
    end
  end
end
