require 'spec_helper'

RSpec.describe Domain::Entities::Factura do
  describe '#initialize' do
    context 'with valid attributes' do
      it 'creates a factura successfully' do
        factura = described_class.new(
          cliente_id: 1,
          fecha_emision: Date.today,
          monto: 1000.50,
          items: [{ descripcion: 'Producto A', cantidad: 2, precio: 500.25 }]
        )

        expect(factura.cliente_id).to eq(1)
        expect(factura.fecha_emision).to eq(Date.today)
        expect(factura.monto).to eq(1000.50)
        expect(factura.estado).to eq('EMITIDA')
        expect(factura.numero_factura).not_to be_nil
      end

      it 'generates a numero_factura automatically' do
        factura = described_class.new(
          cliente_id: 1,
          fecha_emision: Date.today,
          monto: 1000.50
        )

        expect(factura.numero_factura).to match(/^F-\d{8}-[A-F0-9]{8}$/)
      end
    end

    context 'with invalid attributes' do
      it 'raises ArgumentError when cliente_id is nil' do
        expect {
          described_class.new(
            cliente_id: nil,
            fecha_emision: Date.today,
            monto: 1000.50
          )
        }.to raise_error(ArgumentError, 'Cliente ID es requerido')
      end

      it 'raises ArgumentError when fecha_emision is nil' do
        expect {
          described_class.new(
            cliente_id: 1,
            fecha_emision: nil,
            monto: 1000.50
          )
        }.to raise_error(ArgumentError, 'Fecha de emisión es requerida')
      end

      it 'raises ArgumentError when monto is zero' do
        expect {
          described_class.new(
            cliente_id: 1,
            fecha_emision: Date.today,
            monto: 0
          )
        }.to raise_error(ArgumentError, 'Monto debe ser mayor a 0')
      end

      it 'raises ArgumentError when monto is negative' do
        expect {
          described_class.new(
            cliente_id: 1,
            fecha_emision: Date.today,
            monto: -100
          )
        }.to raise_error(ArgumentError, 'Monto debe ser mayor a 0')
      end

      it 'raises ArgumentError when fecha_emision is in the future' do
        expect {
          described_class.new(
            cliente_id: 1,
            fecha_emision: Date.today + 1,
            monto: 1000.50
          )
        }.to raise_error(ArgumentError, 'Fecha de emisión inválida')
      end
    end
  end

  describe '#to_h' do
    it 'converts factura to hash' do
      factura = described_class.new(
        id: 1,
        cliente_id: 1,
        numero_factura: 'F-20250113-ABC123',
        fecha_emision: Date.today,
        monto: 1000.50,
        items: [{ descripcion: 'Producto A', cantidad: 2 }]
      )

      hash = factura.to_h

      expect(hash[:id]).to eq(1)
      expect(hash[:cliente_id]).to eq(1)
      expect(hash[:numero_factura]).to eq('F-20250113-ABC123')
      expect(hash[:monto]).to eq(1000.50)
      expect(hash[:estado]).to eq('EMITIDA')
      expect(hash[:items]).to be_an(Array)
    end
  end
end
