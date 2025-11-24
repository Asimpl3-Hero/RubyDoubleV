require 'spec_helper'
require_relative '../../../app/application/use_cases/get_cliente'
require_relative '../../../app/domain/repositories/cliente_repository'

RSpec.describe Application::UseCases::GetCliente do
  let(:repository) { instance_double(Domain::Repositories::ClienteRepository) }
  let(:auditoria_service_url) { 'http://localhost:4003' }
  let(:use_case) { described_class.new(cliente_repository: repository, auditoria_service_url: auditoria_service_url) }

  describe '#execute' do
    context 'when cliente exists' do
      it 'returns the cliente' do
        cliente = Domain::Entities::Cliente.new(
          id: 1,
          nombre: 'Empresa ABC S.A.',
          identificacion: '900123456',
          correo: 'contacto@empresaabc.com',
          direccion: 'Calle 123 #45-67'
        )

        expect(repository).to receive(:find_by_id).with(1).and_return(cliente)

        result = use_case.execute(id: 1)

        expect(result).to eq(cliente)
        expect(result.id).to eq(1)
        expect(result.nombre).to eq('Empresa ABC S.A.')
      end

      it 'registers a success audit event' do
        cliente = Domain::Entities::Cliente.new(
          id: 1,
          nombre: 'Empresa ABC S.A.',
          identificacion: '900123456',
          correo: 'contacto@empresaabc.com',
          direccion: 'Calle 123 #45-67'
        )

        allow(repository).to receive(:find_by_id).and_return(cliente)

        use_case.execute(id: 1)

        # Verify audit event was published
        expect(Messaging::AuditPublisherMock.events_count).to eq(1)
        event = Messaging::AuditPublisherMock.last_event
        expect(event[:entity_type]).to eq('cliente')
        expect(event[:action]).to eq('READ')
        expect(event[:status]).to eq('SUCCESS')
      end
    end

    context 'when cliente does not exist' do
      it 'raises StandardError' do
        expect(repository).to receive(:find_by_id).with(999).and_return(nil)

        expect {
          use_case.execute(id: 999)
        }.to raise_error(StandardError, 'Cliente con ID 999 no encontrado')
      end

      it 'registers an error audit event' do
        allow(repository).to receive(:find_by_id).and_return(nil)

        expect {
          use_case.execute(id: 999)
        }.to raise_error(StandardError)

        # Verify error audit event was published
        expect(Messaging::AuditPublisherMock.events_count).to eq(1)
        event = Messaging::AuditPublisherMock.last_event
        expect(event[:entity_type]).to eq('cliente')
        expect(event[:action]).to eq('READ')
        expect(event[:status]).to eq('ERROR')
      end
    end

    context 'when audit publisher is available' do
      it 'publishes audit event successfully' do
        cliente = Domain::Entities::Cliente.new(
          id: 1,
          nombre: 'Empresa ABC S.A.',
          identificacion: '900123456',
          correo: 'contacto@empresaabc.com',
          direccion: 'Calle 123 #45-67'
        )

        allow(repository).to receive(:find_by_id).and_return(cliente)

        expect {
          result = use_case.execute(id: 1)
          expect(result).to eq(cliente)
        }.not_to raise_error

        # Verify audit event was published
        expect(Messaging::AuditPublisherMock.events_count).to eq(1)
      end
    end
  end
end
