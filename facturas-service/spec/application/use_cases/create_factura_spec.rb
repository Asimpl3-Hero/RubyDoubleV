require 'spec_helper'
require_relative '../../../app/application/use_cases/create_factura'
require_relative '../../../app/domain/repositories/factura_repository'
require_relative '../../../app/domain/services/cliente_validator'

RSpec.describe Application::UseCases::CreateFactura do
  let(:repository) { instance_double(Domain::Repositories::FacturaRepository) }
  let(:cliente_validator) { instance_double(Domain::Services::ClienteValidator) }
  let(:clientes_service_url) { 'http://localhost:4001' }
  let(:auditoria_service_url) { 'http://localhost:4003' }
  let(:use_case) do
    described_class.new(
      factura_repository: repository,
      clientes_service_url: clientes_service_url,
      auditoria_service_url: auditoria_service_url
    )
  end

  before do
    allow(Domain::Services::ClienteValidator).to receive(:new).and_return(cliente_validator)
  end

  describe '#execute' do
    context 'with valid attributes' do
      it 'creates and saves a factura successfully' do
        saved_factura = Domain::Entities::Factura.new(
          id: 1,
          cliente_id: 10,
          numero_factura: 'F-20250113-ABC123',
          fecha_emision: Date.today,
          monto: 1500.50,
          items: [{ descripcion: 'Producto A', cantidad: 2, precio: 750.25 }]
        )

        expect(cliente_validator).to receive(:cliente_exists?).with(10).and_return(true)
        expect(repository).to receive(:save).and_return(saved_factura)
        allow(HTTParty).to receive(:post).and_return(double(success?: true))

        result = use_case.execute(
          cliente_id: 10,
          fecha_emision: Date.today,
          monto: 1500.50,
          items: [{ descripcion: 'Producto A', cantidad: 2, precio: 750.25 }]
        )

        expect(result).to eq(saved_factura)
        expect(result.id).to eq(1)
        expect(result.cliente_id).to eq(10)
        expect(result.monto).to eq(1500.50)
      end

      it 'parses date string to Date object' do
        saved_factura = Domain::Entities::Factura.new(
          id: 1,
          cliente_id: 10,
          fecha_emision: Date.today,
          monto: 1000.0
        )

        allow(cliente_validator).to receive(:cliente_exists?).and_return(true)
        allow(repository).to receive(:save).and_return(saved_factura)
        allow(HTTParty).to receive(:post).and_return(double(success?: true))

        result = use_case.execute(
          cliente_id: 10,
          fecha_emision: Date.today.to_s,
          monto: 1000.0
        )

        expect(result).to eq(saved_factura)
      end

      it 'registers a success audit event' do
        saved_factura = Domain::Entities::Factura.new(
          id: 1,
          cliente_id: 10,
          numero_factura: 'F-20250113-ABC123',
          fecha_emision: Date.today,
          monto: 1500.50
        )

        allow(cliente_validator).to receive(:cliente_exists?).and_return(true)
        allow(repository).to receive(:save).and_return(saved_factura)

        expect(HTTParty).to receive(:post).with(
          "#{auditoria_service_url}/auditoria",
          hash_including(
            body: String,
            headers: { 'Content-Type' => 'application/json' },
            timeout: 2
          )
        )

        use_case.execute(
          cliente_id: 10,
          fecha_emision: Date.today,
          monto: 1500.50
        )
      end
    end

    context 'when cliente does not exist' do
      it 'raises StandardError' do
        expect(cliente_validator).to receive(:cliente_exists?).with(999).and_return(false)

        expect {
          use_case.execute(
            cliente_id: 999,
            fecha_emision: Date.today,
            monto: 1000.0
          )
        }.to raise_error(StandardError, 'Cliente con ID 999 no existe o no está disponible')
      end

      it 'registers an error audit event' do
        allow(cliente_validator).to receive(:cliente_exists?).and_return(false)

        expect(HTTParty).to receive(:post).with(
          "#{auditoria_service_url}/auditoria",
          hash_including(body: /ERROR/)
        )

        expect {
          use_case.execute(
            cliente_id: 999,
            fecha_emision: Date.today,
            monto: 1000.0
          )
        }.to raise_error(StandardError)
      end
    end

    context 'with invalid attributes' do
      it 'raises ArgumentError when monto is zero' do
        allow(cliente_validator).to receive(:cliente_exists?).and_return(true)

        expect {
          use_case.execute(
            cliente_id: 10,
            fecha_emision: Date.today,
            monto: 0
          )
        }.to raise_error(ArgumentError, 'Monto debe ser mayor a 0')
      end

      it 'raises ArgumentError when fecha_emision is in the future' do
        allow(cliente_validator).to receive(:cliente_exists?).and_return(true)

        expect {
          use_case.execute(
            cliente_id: 10,
            fecha_emision: Date.today + 1,
            monto: 1000.0
          )
        }.to raise_error(ArgumentError, 'Fecha de emisión inválida')
      end
    end

    context 'when save fails' do
      it 'registers an error audit event and raises exception' do
        allow(cliente_validator).to receive(:cliente_exists?).and_return(true)
        allow(repository).to receive(:save).and_raise(StandardError, 'Database error')

        expect(HTTParty).to receive(:post).with(
          "#{auditoria_service_url}/auditoria",
          hash_including(body: /ERROR/)
        )

        expect {
          use_case.execute(
            cliente_id: 10,
            fecha_emision: Date.today,
            monto: 1000.0
          )
        }.to raise_error(StandardError, 'Database error')
      end
    end

    context 'when audit service fails' do
      it 'continues execution and does not raise error' do
        saved_factura = Domain::Entities::Factura.new(
          id: 1,
          cliente_id: 10,
          fecha_emision: Date.today,
          monto: 1000.0
        )

        allow(cliente_validator).to receive(:cliente_exists?).and_return(true)
        allow(repository).to receive(:save).and_return(saved_factura)
        allow(HTTParty).to receive(:post).and_raise(StandardError, 'Audit service down')

        expect {
          result = use_case.execute(
            cliente_id: 10,
            fecha_emision: Date.today,
            monto: 1000.0
          )
          expect(result).to eq(saved_factura)
        }.not_to raise_error
      end
    end
  end
end
