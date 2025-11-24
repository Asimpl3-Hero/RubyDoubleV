require 'spec_helper'
require_relative '../../../app/application/use_cases/list_clientes'
require_relative '../../../app/domain/repositories/cliente_repository'

RSpec.describe Application::UseCases::ListClientes do
  let(:repository) { instance_double(Domain::Repositories::ClienteRepository) }
  let(:auditoria_service_url) { 'http://localhost:4003' }
  let(:use_case) { described_class.new(cliente_repository: repository, auditoria_service_url: auditoria_service_url) }

  describe '#execute' do
    context 'when clientes exist' do
      it 'returns all clientes' do
        clientes = [
          Domain::Entities::Cliente.new(
            id: 1,
            nombre: 'Empresa ABC S.A.',
            identificacion: '900123456',
            correo: 'contacto@abc.com',
            direccion: 'Calle 123'
          ),
          Domain::Entities::Cliente.new(
            id: 2,
            nombre: 'Empresa XYZ Ltda.',
            identificacion: '900654321',
            correo: 'contacto@xyz.com',
            direccion: 'Calle 456'
          )
        ]

        expect(repository).to receive(:find_all).and_return(clientes)

        result = use_case.execute

        expect(result).to eq(clientes)
        expect(result.size).to eq(2)
      end

      it 'registers a success audit event' do
        clientes = [
          Domain::Entities::Cliente.new(
            id: 1,
            nombre: 'Empresa ABC S.A.',
            identificacion: '900123456',
            correo: 'contacto@abc.com',
            direccion: 'Calle 123'
          )
        ]

        allow(repository).to receive(:find_all).and_return(clientes)

        use_case.execute

        # Verify audit event was published
        expect(Messaging::AuditPublisherMock.events_count).to eq(1)
        event = Messaging::AuditPublisherMock.last_event
        expect(event[:entity_type]).to eq('cliente')
        expect(event[:action]).to eq('LIST')
        expect(event[:status]).to eq('SUCCESS')
      end
    end

    context 'when no clientes exist' do
      it 'returns empty array' do
        expect(repository).to receive(:find_all).and_return([])

        result = use_case.execute

        expect(result).to eq([])
        expect(result).to be_empty
      end
    end

    context 'when repository fails' do
      it 'registers an error audit event and raises exception' do
        allow(repository).to receive(:find_all).and_raise(StandardError, 'Database connection failed')

        expect {
          use_case.execute
        }.to raise_error(StandardError, 'Database connection failed')

        # Verify error audit event was published
        expect(Messaging::AuditPublisherMock.events_count).to eq(1)
        event = Messaging::AuditPublisherMock.last_event
        expect(event[:entity_type]).to eq('cliente')
        expect(event[:action]).to eq('LIST')
        expect(event[:status]).to eq('ERROR')
      end
    end

    context 'when audit publisher is available' do
      it 'publishes audit event successfully' do
        clientes = []

        allow(repository).to receive(:find_all).and_return(clientes)

        expect {
          result = use_case.execute
          expect(result).to eq(clientes)
        }.not_to raise_error

        # Verify audit event was published
        expect(Messaging::AuditPublisherMock.events_count).to eq(1)
      end
    end
  end
end
