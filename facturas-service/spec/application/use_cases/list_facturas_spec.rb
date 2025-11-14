require 'spec_helper'
require_relative '../../../app/application/use_cases/list_facturas'
require_relative '../../../app/domain/repositories/factura_repository'

RSpec.describe Application::UseCases::ListFacturas do
  let(:repository) { instance_double(Domain::Repositories::FacturaRepository) }
  let(:auditoria_service_url) { 'http://localhost:4003' }
  let(:use_case) { described_class.new(factura_repository: repository, auditoria_service_url: auditoria_service_url) }

  describe '#execute' do
    context 'when facturas exist' do
      it 'returns all facturas' do
        facturas = [
          Domain::Entities::Factura.new(
            id: 1,
            cliente_id: 10,
            fecha_emision: Date.today,
            monto: 1000.0
          ),
          Domain::Entities::Factura.new(
            id: 2,
            cliente_id: 11,
            fecha_emision: Date.today,
            monto: 2000.0
          )
        ]

        expect(repository).to receive(:find_all).and_return(facturas)
        allow(HTTParty).to receive(:post).and_return(double(success?: true))

        result = use_case.execute

        expect(result).to eq(facturas)
        expect(result.size).to eq(2)
      end

      it 'registers a success audit event' do
        facturas = [
          Domain::Entities::Factura.new(
            id: 1,
            cliente_id: 10,
            fecha_emision: Date.today,
            monto: 1000.0
          )
        ]

        allow(repository).to receive(:find_all).and_return(facturas)

        expect(HTTParty).to receive(:post).with(
          "#{auditoria_service_url}/auditoria",
          hash_including(
            body: /LIST/,
            headers: { 'Content-Type' => 'application/json' }
          )
        )

        use_case.execute
      end
    end

    context 'when no facturas exist' do
      it 'returns empty array' do
        expect(repository).to receive(:find_all).and_return([])
        allow(HTTParty).to receive(:post).and_return(double(success?: true))

        result = use_case.execute

        expect(result).to eq([])
        expect(result).to be_empty
      end
    end

    context 'when repository fails' do
      it 'registers an error audit event and raises exception' do
        allow(repository).to receive(:find_all).and_raise(StandardError, 'Database connection failed')

        expect(HTTParty).to receive(:post).with(
          "#{auditoria_service_url}/auditoria",
          hash_including(body: /ERROR/)
        )

        expect {
          use_case.execute
        }.to raise_error(StandardError, 'Database connection failed')
      end
    end

    context 'when audit service fails' do
      it 'continues execution and does not raise error' do
        facturas = []

        allow(repository).to receive(:find_all).and_return(facturas)
        allow(HTTParty).to receive(:post).and_raise(StandardError, 'Audit service down')

        expect {
          result = use_case.execute
          expect(result).to eq(facturas)
        }.not_to raise_error
      end
    end
  end
end
