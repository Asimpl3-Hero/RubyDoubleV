require 'spec_helper'

RSpec.describe Domain::Entities::Factura do
  describe '#initialize' do
    context 'with valid attributes' do
      it 'creates a factura successfully with IVA' do
        factura = described_class.new(
          cliente_id: 1,
          fecha_emision: Date.today,
          subtotal: 1000.00,
          iva_porcentaje: 19,
          items: [{ descripcion: 'Producto A', cantidad: 2, precio: 500.00 }]
        )

        expect(factura.cliente_id).to eq(1)
        expect(factura.fecha_emision).to eq(Date.today)
        expect(factura.subtotal).to eq(1000.00)
        expect(factura.iva_porcentaje).to eq(19.0)
        expect(factura.iva_valor).to eq(190.0)
        expect(factura.total).to eq(1190.0)
        expect(factura.estado).to eq('EMITIDA')
        expect(factura.numero_factura).not_to be_nil
      end

      it 'creates a factura with default IVA 19%' do
        factura = described_class.new(
          cliente_id: 1,
          fecha_emision: Date.today,
          subtotal: 1000.00
        )

        expect(factura.iva_porcentaje).to eq(19.0)
        expect(factura.iva_valor).to eq(190.0)
        expect(factura.total).to eq(1190.0)
      end

      it 'creates a factura with IVA 0% (exenta)' do
        factura = described_class.new(
          cliente_id: 1,
          fecha_emision: Date.today,
          subtotal: 1000.00,
          iva_porcentaje: 0
        )

        expect(factura.iva_porcentaje).to eq(0.0)
        expect(factura.iva_valor).to eq(0.0)
        expect(factura.total).to eq(1000.0)
      end

      it 'creates a factura with IVA 5%' do
        factura = described_class.new(
          cliente_id: 1,
          fecha_emision: Date.today,
          subtotal: 1000.00,
          iva_porcentaje: 5
        )

        expect(factura.iva_porcentaje).to eq(5.0)
        expect(factura.iva_valor).to eq(50.0)
        expect(factura.total).to eq(1050.0)
      end

      it 'generates a numero_factura automatically' do
        factura = described_class.new(
          cliente_id: 1,
          fecha_emision: Date.today,
          subtotal: 1000.50
        )

        expect(factura.numero_factura).to match(/^F-\d{8}-[A-F0-9]{8}$/)
      end

      it 'supports backward compatibility with monto parameter' do
        factura = described_class.new(
          cliente_id: 1,
          fecha_emision: Date.today,
          monto: 1000.00,
          iva_porcentaje: 19
        )

        expect(factura.subtotal).to eq(1000.00)
        expect(factura.monto).to eq(1190.0) # monto alias returns total
        expect(factura.total).to eq(1190.0)
      end
    end

    context 'with invalid attributes' do
      it 'raises ArgumentError when cliente_id is nil' do
        expect {
          described_class.new(
            cliente_id: nil,
            fecha_emision: Date.today,
            subtotal: 1000.50
          )
        }.to raise_error(ArgumentError, 'Cliente ID es requerido')
      end

      it 'raises ArgumentError when fecha_emision is nil' do
        expect {
          described_class.new(
            cliente_id: 1,
            fecha_emision: nil,
            subtotal: 1000.50
          )
        }.to raise_error(ArgumentError, 'Fecha de emisión es requerida')
      end

      it 'raises ArgumentError when subtotal is zero' do
        expect {
          described_class.new(
            cliente_id: 1,
            fecha_emision: Date.today,
            subtotal: 0
          )
        }.to raise_error(ArgumentError, 'Subtotal debe ser mayor a 0')
      end

      it 'raises ArgumentError when subtotal is negative' do
        expect {
          described_class.new(
            cliente_id: 1,
            fecha_emision: Date.today,
            subtotal: -100
          )
        }.to raise_error(ArgumentError, 'Subtotal debe ser mayor a 0')
      end

      it 'raises ArgumentError when fecha_emision is in the future' do
        expect {
          described_class.new(
            cliente_id: 1,
            fecha_emision: Date.today + 1,
            subtotal: 1000.50
          )
        }.to raise_error(ArgumentError, 'Fecha de emisión inválida')
      end

      it 'raises ArgumentError when iva_porcentaje is invalid' do
        expect {
          described_class.new(
            cliente_id: 1,
            fecha_emision: Date.today,
            subtotal: 1000.00,
            iva_porcentaje: 10
          )
        }.to raise_error(ArgumentError, 'IVA porcentaje debe ser 0, 5, 19%')
      end

      it 'raises ArgumentError when iva_porcentaje is negative' do
        expect {
          described_class.new(
            cliente_id: 1,
            fecha_emision: Date.today,
            subtotal: 1000.00,
            iva_porcentaje: -5
          )
        }.to raise_error(ArgumentError, 'IVA porcentaje debe ser 0, 5, 19%')
      end
    end
  end

  describe '#to_h' do
    it 'converts factura to hash with IVA fields' do
      factura = described_class.new(
        id: 1,
        cliente_id: 1,
        numero_factura: 'F-20250113-ABC123',
        fecha_emision: Date.today,
        subtotal: 1000.00,
        iva_porcentaje: 19,
        items: [{ descripcion: 'Producto A', cantidad: 2 }]
      )

      hash = factura.to_h

      expect(hash[:id]).to eq(1)
      expect(hash[:cliente_id]).to eq(1)
      expect(hash[:numero_factura]).to eq('F-20250113-ABC123')
      expect(hash[:subtotal]).to eq(1000.00)
      expect(hash[:iva_porcentaje]).to eq(19.0)
      expect(hash[:iva_valor]).to eq(190.0)
      expect(hash[:total]).to eq(1190.0)
      expect(hash[:estado]).to eq('EMITIDA')
      expect(hash[:items]).to be_an(Array)
    end
  end
end
