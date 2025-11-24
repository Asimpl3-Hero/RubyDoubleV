require_relative '../../integration_spec_helper'

RSpec.describe 'Integration: Facturas → Clientes → Auditoría', type: :integration do
  let(:clientes_url) { ENV['CLIENTES_SERVICE_URL'] }
  let(:auditoria_url) { ENV['AUDITORIA_SERVICE_URL'] }

  describe 'POST /facturas - Complete flow' do
    context 'when creating a factura with valid cliente' do
      let(:factura_params) do
        {
          cliente_id: 1,
          fecha_emision: Date.today.to_s,
          monto: 1500000,
          items: [
            {
              descripcion: 'Producto A',
              cantidad: 2,
              precio_unitario: 500000,
              subtotal: 1000000
            },
            {
              descripcion: 'Producto B',
              cantidad: 1,
              precio_unitario: 500000,
              subtotal: 500000
            }
          ]
        }
      end

      it 'validates cliente, creates factura, and registers audit events' do
        # Step 1: Mock Clientes service - validate cliente exists
        cliente_stub = stub_request(:get, "#{clientes_url}/clientes/1")
          .to_return(
            status: 200,
            body: {
              success: true,
              data: {
                id: 1,
                nombre: 'Empresa ABC S.A.',
                identificacion: '900123456',
                correo: 'contacto@empresaabc.com',
                direccion: 'Calle 123 #45-67'
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Step 2: Mock Auditoría service - register factura creation event
        audit_stub = stub_request(:post, "#{auditoria_url}/auditoria")
          .with(
            body: hash_including(
              entity_type: 'factura',
              action: 'CREATE',
              status: 'SUCCESS'
            )
          )
          .to_return(
            status: 201,
            body: { success: true, message: 'Evento registrado' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Step 3: Create factura
        post '/facturas', factura_params.to_json, { 'CONTENT_TYPE' => 'application/json' }

        # Verify response
        expect(last_response.status).to eq(201)
        response_body = JSON.parse(last_response.body, symbolize_names: true)

        expect(response_body[:success]).to be true
        expect(response_body[:message]).to eq('Factura creada exitosamente')
        expect(response_body[:data][:cliente_id]).to eq(1)
        expect(response_body[:data][:subtotal]).to eq(1500000.0)
        expect(response_body[:data][:iva_porcentaje]).to eq(19.0)
        expect(response_body[:data][:iva_valor]).to eq(285000.0)
        expect(response_body[:data][:total]).to eq(1785000.0)
        expect(response_body[:data][:estado]).to eq('EMITIDA')
        expect(response_body[:data][:numero_factura]).to match(/^F-\d{8}-[A-F0-9]{8}$/)
        expect(response_body[:data][:items]).to be_an(Array)
        expect(response_body[:data][:items].length).to eq(2)

        # Verify service interactions
        expect(cliente_stub).to have_been_requested.once
        expect(audit_stub).to have_been_requested.once
      end

      it 'sends complete audit metadata including cliente info' do
        # Mock cliente validation
        stub_request(:get, "#{clientes_url}/clientes/1")
          .to_return(
            status: 200,
            body: {
              success: true,
              data: {
                id: 1,
                nombre: 'Empresa ABC S.A.',
                identificacion: '900123456'
              }
            }.to_json
          )

        # Capture audit request
        audit_request = nil
        stub_request(:post, "#{auditoria_url}/auditoria")
          .to_return do |request|
            audit_request = JSON.parse(request.body, symbolize_names: true)
            { status: 201, body: { success: true }.to_json }
          end

        post '/facturas', factura_params.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(audit_request).not_to be_nil
        expect(audit_request[:entity_type]).to eq('factura')
        expect(audit_request[:action]).to eq('CREATE')
        expect(audit_request[:status]).to eq('SUCCESS')
        expect(audit_request[:entity_id]).not_to be_nil
        expect(audit_request[:details]).to be_a(String)
        expect(audit_request[:details]).to match(/Factura .+ creada/)
      end
    end

    context 'when cliente does not exist' do
      let(:factura_params) do
        {
          cliente_id: 999,
          fecha_emision: Date.today.to_s,
          monto: 1000000
        }
      end

      it 'rejects factura and registers error in audit' do
        # Mock Clientes service - cliente not found
        cliente_stub = stub_request(:get, "#{clientes_url}/clientes/999")
          .to_return(
            status: 404,
            body: {
              success: false,
              error: 'Cliente no encontrado'
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Mock Auditoría service - register error
        audit_stub = stub_request(:post, "#{auditoria_url}/auditoria")
          .with(
            body: hash_including(
              entity_type: 'factura',
              action: 'CREATE',
              status: 'ERROR'
            )
          )
          .to_return(status: 201, body: { success: true }.to_json)

        post '/facturas', factura_params.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(422)
        response_body = JSON.parse(last_response.body, symbolize_names: true)

        expect(response_body[:success]).to be false
        expect(response_body[:error]).to include('Cliente')

        expect(cliente_stub).to have_been_requested.once
        expect(audit_stub).to have_been_requested.once
      end
    end

    context 'when Clientes service is unavailable' do
      let(:factura_params) do
        {
          cliente_id: 1,
          fecha_emision: Date.today.to_s,
          monto: 1000000
        }
      end

      it 'fails gracefully and registers error in audit' do
        # Mock Clientes service timeout
        stub_request(:get, "#{clientes_url}/clientes/1")
          .to_timeout

        # Mock Auditoría service
        audit_stub = stub_request(:post, "#{auditoria_url}/auditoria")
          .with(
            body: hash_including(
              entity_type: 'factura',
              action: 'CREATE',
              status: 'ERROR'
            )
          )
          .to_return(status: 201, body: { success: true }.to_json)

        post '/facturas', factura_params.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(422)
        expect(audit_stub).to have_been_requested.once
      end
    end

    context 'when factura has invalid data' do
      let(:invalid_params) do
        {
          cliente_id: 1,
          fecha_emision: Date.today.to_s,
          monto: -1000  # Invalid: negative amount
        }
      end

      it 'validates business rules before checking cliente' do
        # Auditoría should be called to register error
        audit_stub = stub_request(:post, "#{auditoria_url}/auditoria")
          .with(
            body: hash_including(
              entity_type: 'factura',
              action: 'CREATE',
              status: 'ERROR'
            )
          )
          .to_return(status: 201, body: { success: true }.to_json)

        post '/facturas', invalid_params.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(400)
        response_body = JSON.parse(last_response.body, symbolize_names: true)

        expect(response_body[:success]).to be false
        expect(audit_stub).to have_been_requested.once
      end
    end
  end

  describe 'GET /facturas/:id' do
    let!(:factura) do
      FacturaModel.create!(
        cliente_id: 1,
        numero_factura: 'F-20250113-ABC12345',
        fecha_emision: Date.today,
        subtotal: 1500000,
        iva_porcentaje: 19,
        iva_valor: 285000,
        total: 1785000,
        estado: 'EMITIDA',
        items: [{ descripcion: 'Test', cantidad: 1, precio_unitario: 1500000 }]
      )
    end

    it 'retrieves factura and registers audit event' do
      audit_stub = stub_request(:post, "#{auditoria_url}/auditoria")
        .with(
          body: hash_including(
            entity_type: 'factura',
            action: 'READ',
            status: 'SUCCESS',
            entity_id: factura.id
          )
        )
        .to_return(status: 201, body: { success: true }.to_json)

      get "/facturas/#{factura.id}"

      expect(last_response.status).to eq(200)
      response_body = JSON.parse(last_response.body, symbolize_names: true)

      expect(response_body[:success]).to be true
      expect(response_body[:data][:numero_factura]).to eq('F-20250113-ABC12345')
      expect(audit_stub).to have_been_requested.once
    end
  end

  describe 'GET /facturas - with date range filter' do
    before do
      FacturaModel.create!(
        cliente_id: 1,
        numero_factura: 'F-20250101-AAA11111',
        fecha_emision: Date.new(2025, 1, 5),
        subtotal: 1000000,
        iva_porcentaje: 19,
        iva_valor: 190000,
        total: 1190000,
        estado: 'EMITIDA'
      )
      FacturaModel.create!(
        cliente_id: 1,
        numero_factura: 'F-20250115-BBB22222',
        fecha_emision: Date.new(2025, 1, 15),
        subtotal: 2000000,
        iva_porcentaje: 19,
        iva_valor: 380000,
        total: 2380000,
        estado: 'EMITIDA'
      )
      FacturaModel.create!(
        cliente_id: 1,
        numero_factura: 'F-20250125-CCC33333',
        fecha_emision: Date.new(2025, 1, 25),
        subtotal: 3000000,
        iva_porcentaje: 19,
        iva_valor: 570000,
        total: 3570000,
        estado: 'EMITIDA'
      )
    end

    it 'filters facturas by date range and registers audit' do
      audit_stub = stub_request(:post, "#{auditoria_url}/auditoria")
        .with(
          body: hash_including(
            entity_type: 'factura',
            action: 'LIST',
            status: 'SUCCESS'
          )
        )
        .to_return(status: 201, body: { success: true }.to_json)

      get '/facturas?fechaInicio=2025-01-10&fechaFin=2025-01-20'

      expect(last_response.status).to eq(200)
      response_body = JSON.parse(last_response.body, symbolize_names: true)

      expect(response_body[:success]).to be true
      expect(response_body[:data]).to be_an(Array)
      expect(response_body[:data].length).to eq(1)
      expect(response_body[:data][0][:numero_factura]).to eq('F-20250115-BBB22222')
      expect(audit_stub).to have_been_requested.once
    end
  end

  describe 'End-to-end resilience' do
    let(:factura_params) do
      {
        cliente_id: 1,
        fecha_emision: Date.today.to_s,
        monto: 1000000
      }
    end

    context 'when Auditoría service fails' do
      it 'still creates factura if cliente is valid' do
        # Mock successful cliente validation
        stub_request(:get, "#{clientes_url}/clientes/1")
          .to_return(
            status: 200,
            body: {
              success: true,
              data: { id: 1, nombre: 'Test Cliente' }
            }.to_json
          )

        # Mock Auditoría failure
        stub_request(:post, "#{auditoria_url}/auditoria")
          .to_return(status: 500)

        post '/facturas', factura_params.to_json, { 'CONTENT_TYPE' => 'application/json' }

        # Factura should still be created (audit is async/non-critical)
        expect(last_response.status).to eq(201)
        response_body = JSON.parse(last_response.body, symbolize_names: true)
        expect(response_body[:success]).to be true

        # Verify factura exists in database
        factura = FacturaModel.last
        expect(factura.cliente_id).to eq(1)
        expect(factura.subtotal).to eq(1000000)
        expect(factura.total).to eq(1190000)
      end
    end

    context 'when both external services fail' do
      it 'fails factura creation gracefully' do
        # Mock both services failing
        stub_request(:get, "#{clientes_url}/clientes/1")
          .to_timeout

        stub_request(:post, "#{auditoria_url}/auditoria")
          .to_timeout

        post '/facturas', factura_params.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(422)
        response_body = JSON.parse(last_response.body, symbolize_names: true)
        expect(response_body[:success]).to be false
      end
    end
  end
end
