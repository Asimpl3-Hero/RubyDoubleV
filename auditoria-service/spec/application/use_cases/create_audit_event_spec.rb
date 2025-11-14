require 'spec_helper'
require_relative '../../../app/application/use_cases/create_audit_event'
require_relative '../../../app/domain/repositories/audit_event_repository'

RSpec.describe Application::UseCases::CreateAuditEvent do
  let(:repository) { instance_double(Domain::Repositories::AuditEventRepository) }
  let(:use_case) { described_class.new(audit_event_repository: repository) }

  describe '#execute' do
    context 'with valid attributes' do
      it 'creates and saves an audit event successfully' do
        saved_event = Domain::Entities::AuditEvent.new(
          id: 'abc123',
          entity_type: 'Cliente',
          entity_id: 1,
          action: 'CREATE',
          details: 'Cliente creado: Empresa ABC',
          status: 'SUCCESS'
        )

        expect(repository).to receive(:save).and_return(saved_event)

        result = use_case.execute(
          entity_type: 'Cliente',
          entity_id: 1,
          action: 'CREATE',
          details: 'Cliente creado: Empresa ABC',
          status: 'SUCCESS'
        )

        expect(result).to eq(saved_event)
        expect(result.id).to eq('abc123')
      end

      it 'passes custom timestamp to the entity' do
        custom_timestamp = Time.now.utc.iso8601

        saved_event = Domain::Entities::AuditEvent.new(
          id: 'abc123',
          entity_type: 'Factura',
          entity_id: 2,
          action: 'READ',
          details: 'Factura consultada',
          status: 'SUCCESS',
          timestamp: custom_timestamp
        )

        expect(repository).to receive(:save).and_return(saved_event)

        result = use_case.execute(
          entity_type: 'Factura',
          entity_id: 2,
          action: 'READ',
          details: 'Factura consultada',
          status: 'SUCCESS',
          timestamp: custom_timestamp
        )

        expect(result.timestamp).to eq(custom_timestamp)
      end
    end

    context 'with invalid attributes' do
      it 'raises ArgumentError when entity_type is empty' do
        expect {
          use_case.execute(
            entity_type: '',
            entity_id: 1,
            action: 'CREATE',
            details: 'Test',
            status: 'SUCCESS'
          )
        }.to raise_error(ArgumentError, 'entity_type es requerido')
      end

      it 'raises ArgumentError when status is invalid' do
        expect {
          use_case.execute(
            entity_type: 'Cliente',
            entity_id: 1,
            action: 'CREATE',
            details: 'Test',
            status: 'INVALID'
          )
        }.to raise_error(ArgumentError, 'status debe ser SUCCESS o ERROR')
      end
    end

    context 'when repository fails' do
      it 'raises StandardError with descriptive message' do
        allow(repository).to receive(:save).and_raise(StandardError, 'Database connection failed')

        expect {
          use_case.execute(
            entity_type: 'Cliente',
            entity_id: 1,
            action: 'CREATE',
            details: 'Test',
            status: 'SUCCESS'
          )
        }.to raise_error(StandardError, 'Error al crear evento de auditoría: Database connection failed')
      end
    end
  end
end
