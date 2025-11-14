require 'spec_helper'
require 'active_record'
require_relative '../../../app/infrastructure/persistence/active_record_cliente_repository'
require_relative '../../../app/domain/repositories/cliente_repository'
require_relative '../../../app/infrastructure/persistence/cliente_model'

RSpec.describe Infrastructure::Persistence::ActiveRecordClienteRepository do
  let(:repository) { described_class.new }

  # Mock ClienteModel
  let(:cliente_model) { double('ClienteModel', id: 1, nombre: 'Test', identificacion: '123', correo: 'test@test.com', direccion: 'Test St', created_at: Time.now, updated_at: Time.now) }

  describe '#save' do
    it 'saves cliente to database and returns entity' do
      cliente = Domain::Entities::Cliente.new(
        nombre: 'Empresa ABC S.A.',
        identificacion: '900123456',
        correo: 'contacto@empresaabc.com',
        direccion: 'Calle 123 #45-67'
      )

      expect(ClienteModel).to receive(:create!).with(
        nombre: 'Empresa ABC S.A.',
        identificacion: '900123456',
        correo: 'contacto@empresaabc.com',
        direccion: 'Calle 123 #45-67'
      ).and_return(cliente_model)

      result = repository.save(cliente)

      expect(result).to be_a(Domain::Entities::Cliente)
      expect(result.id).to eq(1)
      expect(result.nombre).to eq('Test')
    end
  end

  describe '#find_by_id' do
    context 'when cliente exists' do
      it 'returns the cliente entity' do
        expect(ClienteModel).to receive(:find_by).with(id: 1).and_return(cliente_model)

        result = repository.find_by_id(1)

        expect(result).to be_a(Domain::Entities::Cliente)
        expect(result.id).to eq(1)
      end
    end

    context 'when cliente does not exist' do
      it 'returns nil' do
        expect(ClienteModel).to receive(:find_by).with(id: 999).and_return(nil)

        result = repository.find_by_id(999)

        expect(result).to be_nil
      end
    end
  end

  describe '#find_all' do
    it 'returns all clientes as entities' do
      models = [cliente_model, cliente_model]
      expect(ClienteModel).to receive(:all).and_return(models)

      result = repository.find_all

      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
      expect(result.first).to be_a(Domain::Entities::Cliente)
    end

    it 'returns empty array when no clientes exist' do
      expect(ClienteModel).to receive(:all).and_return([])

      result = repository.find_all

      expect(result).to eq([])
    end
  end

  describe '#find_by_identificacion' do
    context 'when cliente exists' do
      it 'returns the cliente entity' do
        expect(ClienteModel).to receive(:find_by).with(identificacion: '900123456').and_return(cliente_model)

        result = repository.find_by_identificacion('900123456')

        expect(result).to be_a(Domain::Entities::Cliente)
        expect(result.id).to eq(1)
      end
    end

    context 'when cliente does not exist' do
      it 'returns nil' do
        expect(ClienteModel).to receive(:find_by).with(identificacion: '999999999').and_return(nil)

        result = repository.find_by_identificacion('999999999')

        expect(result).to be_nil
      end
    end
  end

  describe '#update' do
    it 'updates cliente and returns entity' do
      expect(ClienteModel).to receive(:find).with(1).and_return(cliente_model)
      expect(cliente_model).to receive(:update!).with(hash_including(nombre: 'Updated Name'))
      expect(cliente_model).to receive(:nombre).and_return('Updated Name')

      result = repository.update(1, nombre: 'Updated Name')

      expect(result).to be_a(Domain::Entities::Cliente)
      expect(result.nombre).to eq('Updated Name')
    end
  end

  describe '#delete' do
    it 'deletes cliente from database' do
      expect(ClienteModel).to receive(:find).with(1).and_return(cliente_model)
      expect(cliente_model).to receive(:destroy)

      repository.delete(1)
    end
  end
end
