require 'spec_helper'
require_relative '../../../app/application/use_cases/list_audit_events'
require_relative '../../../app/domain/repositories/audit_event_repository'

RSpec.describe Application::UseCases::ListAuditEvents do
  let(:repository) { instance_double(Domain::Repositories::AuditEventRepository) }
  let(:use_case) { described_class.new(audit_event_repository: repository) }

  describe '#execute' do
    context 'without filters' do
      it 'returns all events with default limit' do
        events = [
          Domain::Entities::AuditEvent.new(
            id: 'event1',
            entity_type: 'Cliente',
            entity_id: 1,
            action: 'CREATE',
            details: 'Cliente creado',
            status: 'SUCCESS'
          ),
          Domain::Entities::AuditEvent.new(
            id: 'event2',
            entity_type: 'Factura',
            entity_id: 2,
            action: 'CREATE',
            details: 'Factura creada',
            status: 'SUCCESS'
          )
        ]

        expect(repository).to receive(:find_all).with(limit: 100).and_return(events)

        result = use_case.execute

        expect(result).to eq(events)
        expect(result.size).to eq(2)
      end

      it 'returns events with custom limit' do
        events = []
        expect(repository).to receive(:find_all).with(limit: 50).and_return(events)

        result = use_case.execute(limit: 50)

        expect(result).to eq(events)
      end
    end

    context 'with action filter' do
      it 'returns events filtered by action' do
        events = [
          Domain::Entities::AuditEvent.new(
            id: 'event1',
            entity_type: 'Cliente',
            entity_id: 1,
            action: 'CREATE',
            details: 'Cliente creado',
            status: 'SUCCESS'
          )
        ]

        expect(repository).to receive(:find_by_action).with(action: 'CREATE', limit: 100).and_return(events)

        result = use_case.execute(action: 'CREATE')

        expect(result).to eq(events)
        expect(result.size).to eq(1)
        expect(result.first.action).to eq('CREATE')
      end
    end

    context 'with status filter' do
      it 'returns events filtered by status' do
        events = [
          Domain::Entities::AuditEvent.new(
            id: 'event1',
            entity_type: 'Cliente',
            entity_id: 1,
            action: 'CREATE',
            details: 'Error al crear cliente',
            status: 'ERROR'
          )
        ]

        expect(repository).to receive(:find_by_status).with(status: 'ERROR', limit: 100).and_return(events)

        result = use_case.execute(status: 'ERROR')

        expect(result).to eq(events)
        expect(result.size).to eq(1)
        expect(result.first.status).to eq('ERROR')
      end
    end

    context 'when repository fails' do
      it 'raises StandardError with descriptive message' do
        allow(repository).to receive(:find_all).and_raise(StandardError, 'Database error')

        expect {
          use_case.execute
        }.to raise_error(StandardError, 'Error al listar eventos de auditoría: Database error')
      end
    end
  end
end
