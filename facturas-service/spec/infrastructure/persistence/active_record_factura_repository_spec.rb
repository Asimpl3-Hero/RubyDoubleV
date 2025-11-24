require 'spec_helper'
require 'active_record'
require_relative '../../../app/infrastructure/persistence/active_record_factura_repository'
require_relative '../../../app/domain/repositories/factura_repository'
require_relative '../../../app/infrastructure/persistence/factura_model'

RSpec.describe Infrastructure::Persistence::ActiveRecordFacturaRepository do
  let(:repository) { described_class.new }

  # Mock FacturaModel (using double instead of instance_double for ActiveRecord dynamic methods)
  let(:factura_model) do
    double(
      'FacturaModel',
      id: 1,
      cliente_id: 10,
      numero_factura: 'F-20250113-ABC123',
      fecha_emision: Date.today,
      subtotal: 1500.50,
      iva_porcentaje: 19.0,
      iva_valor: 285.10,
      total: 1785.60,
      estado: 'EMITIDA',
      items: [{ descripcion: 'Producto A', cantidad: 2 }].to_json,
      created_at: Time.now,
      updated_at: Time.now
    )
  end

  describe '#save' do
    it 'saves factura to database and returns entity' do
      factura = Domain::Entities::Factura.new(
        cliente_id: 10,
        numero_factura: 'F-20250113-ABC123',
        fecha_emision: Date.today,
        subtotal: 1500.50,
        iva_porcentaje: 19,
        items: [{ descripcion: 'Producto A', cantidad: 2 }]
      )

      expect(FacturaModel).to receive(:create!).with(
        hash_including(
          cliente_id: 10,
          numero_factura: 'F-20250113-ABC123',
          fecha_emision: Date.today,
          subtotal: 1500.50,
          iva_porcentaje: 19.0,
          iva_valor: 285.10,
          total: 1785.60,
          estado: 'EMITIDA'
        )
      ).and_return(factura_model)

      result = repository.save(factura)

      expect(result).to be_a(Domain::Entities::Factura)
      expect(result.id).to eq(1)
      expect(result.cliente_id).to eq(10)
    end
  end

  describe '#find_by_id' do
    context 'when factura exists' do
      it 'returns the factura entity' do
        expect(FacturaModel).to receive(:find_by).with(id: 1).and_return(factura_model)

        result = repository.find_by_id(1)

        expect(result).to be_a(Domain::Entities::Factura)
        expect(result.id).to eq(1)
        expect(result.numero_factura).to eq('F-20250113-ABC123')
      end
    end

    context 'when factura does not exist' do
      it 'returns nil' do
        expect(FacturaModel).to receive(:find_by).with(id: 999).and_return(nil)

        result = repository.find_by_id(999)

        expect(result).to be_nil
      end
    end
  end

  describe '#find_all' do
    it 'returns all facturas as entities' do
      models = [factura_model, factura_model]
      relation = double('ActiveRecord::Relation')
      expect(FacturaModel).to receive(:all).and_return(relation)
      expect(relation).to receive(:order).with(fecha_emision: :desc).and_return(models)

      result = repository.find_all

      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
      expect(result.first).to be_a(Domain::Entities::Factura)
    end

    it 'returns empty array when no facturas exist' do
      relation = double('ActiveRecord::Relation')
      expect(FacturaModel).to receive(:all).and_return(relation)
      expect(relation).to receive(:order).with(fecha_emision: :desc).and_return([])

      result = repository.find_all

      expect(result).to eq([])
    end
  end

  describe '#find_by_cliente_id' do
    context 'when facturas exist for cliente' do
      it 'returns all facturas for the cliente' do
        models = [factura_model]
        relation = double('ActiveRecord::Relation')
        expect(FacturaModel).to receive(:where).with(cliente_id: 10).and_return(relation)
        expect(relation).to receive(:order).with(fecha_emision: :desc).and_return(models)

        result = repository.find_by_cliente_id(10)

        expect(result).to be_an(Array)
        expect(result.size).to eq(1)
        expect(result.first).to be_a(Domain::Entities::Factura)
        expect(result.first.cliente_id).to eq(10)
      end
    end

    context 'when no facturas exist for cliente' do
      it 'returns empty array' do
        relation = double('ActiveRecord::Relation')
        expect(FacturaModel).to receive(:where).with(cliente_id: 999).and_return(relation)
        expect(relation).to receive(:order).with(fecha_emision: :desc).and_return([])

        result = repository.find_by_cliente_id(999)

        expect(result).to eq([])
      end
    end
  end

  describe '#update' do
    it 'updates factura and returns entity' do
      expect(FacturaModel).to receive(:find).with(1).and_return(factura_model)
      expect(factura_model).to receive(:update!).with(hash_including(estado: 'PAGADA'))
      expect(factura_model).to receive(:estado).and_return('PAGADA')

      result = repository.update(1, estado: 'PAGADA')

      expect(result).to be_a(Domain::Entities::Factura)
      expect(result.estado).to eq('PAGADA')
    end
  end

  describe '#delete' do
    it 'deletes factura from database' do
      expect(FacturaModel).to receive(:find).with(1).and_return(factura_model)
      expect(factura_model).to receive(:destroy)

      repository.delete(1)
    end
  end
end
