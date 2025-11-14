require 'spec_helper'

RSpec.describe Domain::Entities::AuditEvent do
  describe '#initialize' do
    context 'with valid attributes' do
      it 'creates an audit event successfully' do
        audit_event = described_class.new(
          entity_type: 'Cliente',
          entity_id: 1,
          action: 'CREATE',
          details: 'Cliente creado: Empresa ABC',
          status: 'SUCCESS'
        )

        expect(audit_event.entity_type).to eq('Cliente')
        expect(audit_event.entity_id).to eq(1)
        expect(audit_event.action).to eq('CREATE')
        expect(audit_event.details).to eq('Cliente creado: Empresa ABC')
        expect(audit_event.status).to eq('SUCCESS')
        expect(audit_event.timestamp).not_to be_nil
        expect(audit_event.created_at).not_to be_nil
      end

      it 'accepts custom timestamp and created_at' do
        custom_time = Time.now.utc
        custom_timestamp = custom_time.iso8601

        audit_event = described_class.new(
          entity_type: 'Factura',
          entity_id: 2,
          action: 'READ',
          details: 'Factura consultada',
          status: 'SUCCESS',
          timestamp: custom_timestamp,
          created_at: custom_time
        )

        expect(audit_event.timestamp).to eq(custom_timestamp)
        expect(audit_event.created_at).to eq(custom_time)
      end

      it 'accepts nil entity_id' do
        audit_event = described_class.new(
          entity_type: 'Cliente',
          entity_id: nil,
          action: 'LIST',
          details: 'Listado de clientes',
          status: 'SUCCESS'
        )

        expect(audit_event.entity_id).to be_nil
      end
    end

    context 'with invalid attributes' do
      it 'raises ArgumentError when entity_type is empty' do
        expect {
          described_class.new(
            entity_type: '',
            entity_id: 1,
            action: 'CREATE',
            details: 'Test details',
            status: 'SUCCESS'
          )
        }.to raise_error(ArgumentError, 'entity_type es requerido')
      end

      it 'raises ArgumentError when entity_type is nil' do
        expect {
          described_class.new(
            entity_type: nil,
            entity_id: 1,
            action: 'CREATE',
            details: 'Test details',
            status: 'SUCCESS'
          )
        }.to raise_error(ArgumentError, 'entity_type es requerido')
      end

      it 'raises ArgumentError when action is empty' do
        expect {
          described_class.new(
            entity_type: 'Cliente',
            entity_id: 1,
            action: '',
            details: 'Test details',
            status: 'SUCCESS'
          )
        }.to raise_error(ArgumentError, 'action es requerido')
      end

      it 'raises ArgumentError when details is empty' do
        expect {
          described_class.new(
            entity_type: 'Cliente',
            entity_id: 1,
            action: 'CREATE',
            details: '',
            status: 'SUCCESS'
          )
        }.to raise_error(ArgumentError, 'details es requerido')
      end

      it 'raises ArgumentError when status is empty' do
        expect {
          described_class.new(
            entity_type: 'Cliente',
            entity_id: 1,
            action: 'CREATE',
            details: 'Test details',
            status: ''
          )
        }.to raise_error(ArgumentError, 'status es requerido')
      end

      it 'raises ArgumentError when status is invalid' do
        expect {
          described_class.new(
            entity_type: 'Cliente',
            entity_id: 1,
            action: 'CREATE',
            details: 'Test details',
            status: 'INVALID_STATUS'
          )
        }.to raise_error(ArgumentError, 'status debe ser SUCCESS o ERROR')
      end
    end
  end

  describe '#to_h' do
    it 'converts audit event to hash' do
      audit_event = described_class.new(
        id: 'abc123',
        entity_type: 'Cliente',
        entity_id: 1,
        action: 'CREATE',
        details: 'Cliente creado: Empresa ABC',
        status: 'SUCCESS'
      )

      hash = audit_event.to_h

      expect(hash[:id]).to eq('abc123')
      expect(hash[:entity_type]).to eq('Cliente')
      expect(hash[:entity_id]).to eq(1)
      expect(hash[:action]).to eq('CREATE')
      expect(hash[:details]).to eq('Cliente creado: Empresa ABC')
      expect(hash[:status]).to eq('SUCCESS')
      expect(hash[:timestamp]).not_to be_nil
      expect(hash[:created_at]).not_to be_nil
    end

    it 'converts id to string when id is not nil' do
      audit_event = described_class.new(
        id: 123,
        entity_type: 'Cliente',
        entity_id: 1,
        action: 'CREATE',
        details: 'Test',
        status: 'SUCCESS'
      )

      hash = audit_event.to_h
      expect(hash[:id]).to eq('123')
    end

    it 'returns nil for id when id is nil' do
      audit_event = described_class.new(
        entity_type: 'Cliente',
        entity_id: 1,
        action: 'CREATE',
        details: 'Test',
        status: 'SUCCESS'
      )

      hash = audit_event.to_h
      expect(hash[:id]).to be_nil
    end
  end
end
