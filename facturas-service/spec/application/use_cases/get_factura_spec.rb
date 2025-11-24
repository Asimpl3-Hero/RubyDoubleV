require 'spec_helper'
require_relative '../../../app/application/use_cases/get_factura'
require_relative '../../../app/domain/repositories/factura_repository'

RSpec.describe Application::UseCases::GetFactura do
  let(:repository) { instance_double(Domain::Repositories::FacturaRepository) }
  let(:auditoria_service_url) { 'http://localhost:4003' }
  let(:use_case) { described_class.new(factura_repository: repository, auditoria_service_url: auditoria_service_url) }

  describe '#execute' do
    context 'when factura exists' do
      it 'returns the factura' do
        factura = Domain::Entities::Factura.new(
          id: 1,
          cliente_id: 10,
          numero_factura: 'F-20250113-ABC123',
          fecha_emision: Date.today,
          monto: 1500.50,
          items: [{ descripcion: 'Producto A', cantidad: 2 }]
        )

        expect(repository).to receive(:find_by_id).with(1).and_return(factura)

        result = use_case.execute(id: 1)

        expect(result).to eq(factura)
        expect(result.id).to eq(1)
        expect(result.numero_factura).to eq('F-20250113-ABC123')
      end

      it 'registers a success audit event' do
        factura = Domain::Entities::Factura.new(
          id: 1,
          cliente_id: 10,
          fecha_emision: Date.today,
          monto: 1000.0
        )

        allow(repository).to receive(:find_by_id).and_return(factura)

        use_case.execute(id: 1)

        # Verify audit event was published
        expect(Messaging::AuditPublisherMock.events_count).to eq(1)
        event = Messaging::AuditPublisherMock.last_event
        expect(event[:entity_type]).to eq('factura')
        expect(event[:action]).to eq('READ')
        expect(event[:status]).to eq('SUCCESS')
      end
    end

    context 'when factura does not exist' do
      it 'raises StandardError' do
        expect(repository).to receive(:find_by_id).with(999).and_return(nil)

        expect {
          use_case.execute(id: 999)
        }.to raise_error(StandardError, 'Factura con ID 999 no encontrada')
      end

      it 'registers an error audit event' do
        allow(repository).to receive(:find_by_id).and_return(nil)

        expect {
          use_case.execute(id: 999)
        }.to raise_error(StandardError)

        # Verify error audit event was published
        expect(Messaging::AuditPublisherMock.events_count).to eq(1)
        event = Messaging::AuditPublisherMock.last_event
        expect(event[:entity_type]).to eq('factura')
        expect(event[:action]).to eq('READ')
        expect(event[:status]).to eq('ERROR')
      end
    end

    context 'when audit publisher is available' do
      it 'publishes audit event successfully' do
        factura = Domain::Entities::Factura.new(
          id: 1,
          cliente_id: 10,
          fecha_emision: Date.today,
          monto: 1000.0
        )

        allow(repository).to receive(:find_by_id).and_return(factura)

        expect {
          result = use_case.execute(id: 1)
          expect(result).to eq(factura)
        }.not_to raise_error

        # Verify audit event was published
        expect(Messaging::AuditPublisherMock.events_count).to eq(1)
      end
    end
  end
end
