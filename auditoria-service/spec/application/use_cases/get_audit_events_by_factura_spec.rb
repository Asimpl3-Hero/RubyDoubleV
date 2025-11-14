require 'spec_helper'
require_relative '../../../app/application/use_cases/get_audit_events_by_factura'
require_relative '../../../app/domain/repositories/audit_event_repository'

RSpec.describe Application::UseCases::GetAuditEventsByFactura do
  let(:repository) { instance_double(Domain::Repositories::AuditEventRepository) }
  let(:use_case) { described_class.new(audit_event_repository: repository) }

  describe '#execute' do
    context 'when events exist for the factura' do
      it 'returns all events for the factura_id' do
        events = [
          Domain::Entities::AuditEvent.new(
            id: 'event1',
            entity_type: 'Factura',
            entity_id: 100,
            action: 'CREATE',
            details: 'Factura creada',
            status: 'SUCCESS'
          ),
          Domain::Entities::AuditEvent.new(
            id: 'event2',
            entity_type: 'Factura',
            entity_id: 100,
            action: 'READ',
            details: 'Factura consultada',
            status: 'SUCCESS'
          )
        ]

        expect(repository).to receive(:find_by_factura_id).with(100).and_return(events)

        result = use_case.execute(factura_id: 100)

        expect(result).to eq(events)
        expect(result.size).to eq(2)
      end
    end

    context 'when no events exist for the factura' do
      it 'returns an empty array' do
        expect(repository).to receive(:find_by_factura_id).with(999).and_return([])

        result = use_case.execute(factura_id: 999)

        expect(result).to eq([])
      end
    end

    context 'when repository fails' do
      it 'raises StandardError with descriptive message' do
        allow(repository).to receive(:find_by_factura_id).and_raise(StandardError, 'MongoDB connection error')

        expect {
          use_case.execute(factura_id: 100)
        }.to raise_error(StandardError, 'Error al consultar eventos de auditoría: MongoDB connection error')
      end
    end
  end
end
