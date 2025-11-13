require 'spec_helper'

RSpec.describe Domain::Entities::Cliente do
  describe '#initialize' do
    context 'with valid attributes' do
      it 'creates a cliente successfully' do
        cliente = described_class.new(
          nombre: 'Empresa ABC S.A.',
          identificacion: '900123456',
          correo: 'contacto@empresaabc.com',
          direccion: 'Calle 123 #45-67'
        )

        expect(cliente.nombre).to eq('Empresa ABC S.A.')
        expect(cliente.identificacion).to eq('900123456')
        expect(cliente.correo).to eq('contacto@empresaabc.com')
        expect(cliente.direccion).to eq('Calle 123 #45-67')
      end
    end

    context 'with invalid attributes' do
      it 'raises ArgumentError when nombre is empty' do
        expect {
          described_class.new(
            nombre: '',
            identificacion: '900123456',
            correo: 'contacto@empresaabc.com',
            direccion: 'Calle 123 #45-67'
          )
        }.to raise_error(ArgumentError, 'Nombre es requerido')
      end

      it 'raises ArgumentError when identificacion is empty' do
        expect {
          described_class.new(
            nombre: 'Empresa ABC S.A.',
            identificacion: '',
            correo: 'contacto@empresaabc.com',
            direccion: 'Calle 123 #45-67'
          )
        }.to raise_error(ArgumentError, 'Identificación es requerida')
      end

      it 'raises ArgumentError when correo is empty' do
        expect {
          described_class.new(
            nombre: 'Empresa ABC S.A.',
            identificacion: '900123456',
            correo: '',
            direccion: 'Calle 123 #45-67'
          )
        }.to raise_error(ArgumentError, 'Correo es requerido')
      end

      it 'raises ArgumentError when correo format is invalid' do
        expect {
          described_class.new(
            nombre: 'Empresa ABC S.A.',
            identificacion: '900123456',
            correo: 'correo-invalido',
            direccion: 'Calle 123 #45-67'
          )
        }.to raise_error(ArgumentError, 'Formato de correo inválido')
      end

      it 'raises ArgumentError when direccion is empty' do
        expect {
          described_class.new(
            nombre: 'Empresa ABC S.A.',
            identificacion: '900123456',
            correo: 'contacto@empresaabc.com',
            direccion: ''
          )
        }.to raise_error(ArgumentError, 'Dirección es requerida')
      end
    end
  end

  describe '#to_h' do
    it 'converts cliente to hash' do
      cliente = described_class.new(
        id: 1,
        nombre: 'Empresa ABC S.A.',
        identificacion: '900123456',
        correo: 'contacto@empresaabc.com',
        direccion: 'Calle 123 #45-67'
      )

      hash = cliente.to_h

      expect(hash[:id]).to eq(1)
      expect(hash[:nombre]).to eq('Empresa ABC S.A.')
      expect(hash[:identificacion]).to eq('900123456')
      expect(hash[:correo]).to eq('contacto@empresaabc.com')
      expect(hash[:direccion]).to eq('Calle 123 #45-67')
    end
  end
end
