require 'spec_helper'
require_relative '../../../app/application/use_cases/create_cliente'
require_relative '../../../app/domain/repositories/cliente_repository'

RSpec.describe Application::UseCases::CreateCliente do
  let(:repository) { instance_double(Domain::Repositories::ClienteRepository) }
  let(:auditoria_service_url) { 'http://localhost:4003' }
  let(:use_case) { described_class.new(cliente_repository: repository, auditoria_service_url: auditoria_service_url) }

  describe '#execute' do
    context 'with valid attributes' do
      it 'creates and saves a cliente successfully' do
        saved_cliente = Domain::Entities::Cliente.new(
          id: 1,
          nombre: 'Empresa ABC S.A.',
          identificacion: '900123456',
          correo: 'contacto@empresaabc.com',
          direccion: 'Calle 123 #45-67'
        )

        expect(repository).to receive(:find_by_identificacion).with('900123456').and_return(nil)
        expect(repository).to receive(:save).and_return(saved_cliente)

        # Stub HTTParty call to auditoría service
        allow(HTTParty).to receive(:post).and_return(double(success?: true))

        result = use_case.execute(
          nombre: 'Empresa ABC S.A.',
          identificacion: '900123456',
          correo: 'contacto@empresaabc.com',
          direccion: 'Calle 123 #45-67'
        )

        expect(result).to eq(saved_cliente)
        expect(result.id).to eq(1)
        expect(result.nombre).to eq('Empresa ABC S.A.')
      end

      it 'registers a success audit event' do
        saved_cliente = Domain::Entities::Cliente.new(
          id: 1,
          nombre: 'Empresa ABC S.A.',
          identificacion: '900123456',
          correo: 'contacto@empresaabc.com',
          direccion: 'Calle 123 #45-67'
        )

        allow(repository).to receive(:find_by_identificacion).and_return(nil)
        allow(repository).to receive(:save).and_return(saved_cliente)

        expect(HTTParty).to receive(:post).with(
          "#{auditoria_service_url}/auditoria",
          hash_including(
            body: String,
            headers: { 'Content-Type' => 'application/json' },
            timeout: 2
          )
        )

        use_case.execute(
          nombre: 'Empresa ABC S.A.',
          identificacion: '900123456',
          correo: 'contacto@empresaabc.com',
          direccion: 'Calle 123 #45-67'
        )
      end
    end

    context 'when cliente already exists' do
      it 'raises StandardError' do
        existing_cliente = Domain::Entities::Cliente.new(
          id: 1,
          nombre: 'Empresa Existente',
          identificacion: '900123456',
          correo: 'existente@empresa.com',
          direccion: 'Calle 456'
        )

        expect(repository).to receive(:find_by_identificacion).with('900123456').and_return(existing_cliente)

        expect {
          use_case.execute(
            nombre: 'Nueva Empresa',
            identificacion: '900123456',
            correo: 'nueva@empresa.com',
            direccion: 'Calle 789'
          )
        }.to raise_error(StandardError, 'Cliente con identificación 900123456 ya existe')
      end
    end

    context 'with invalid attributes' do
      it 'raises ArgumentError when correo format is invalid' do
        allow(repository).to receive(:find_by_identificacion).and_return(nil)

        expect {
          use_case.execute(
            nombre: 'Empresa ABC S.A.',
            identificacion: '900123456',
            correo: 'correo-invalido',
            direccion: 'Calle 123'
          )
        }.to raise_error(ArgumentError, 'Formato de correo inválido')
      end
    end

    context 'when save fails' do
      it 'registers an error audit event and raises exception' do
        allow(repository).to receive(:find_by_identificacion).and_return(nil)
        allow(repository).to receive(:save).and_raise(StandardError, 'Database error')

        expect(HTTParty).to receive(:post).with(
          "#{auditoria_service_url}/auditoria",
          hash_including(body: /ERROR/)
        )

        expect {
          use_case.execute(
            nombre: 'Empresa ABC S.A.',
            identificacion: '900123456',
            correo: 'contacto@empresaabc.com',
            direccion: 'Calle 123'
          )
        }.to raise_error(StandardError, 'Database error')
      end
    end

    context 'when audit service fails' do
      it 'continues execution and does not raise error' do
        saved_cliente = Domain::Entities::Cliente.new(
          id: 1,
          nombre: 'Empresa ABC S.A.',
          identificacion: '900123456',
          correo: 'contacto@empresaabc.com',
          direccion: 'Calle 123 #45-67'
        )

        allow(repository).to receive(:find_by_identificacion).and_return(nil)
        allow(repository).to receive(:save).and_return(saved_cliente)
        allow(HTTParty).to receive(:post).and_raise(StandardError, 'Audit service down')

        # Should not raise error even if audit fails
        expect {
          result = use_case.execute(
            nombre: 'Empresa ABC S.A.',
            identificacion: '900123456',
            correo: 'contacto@empresaabc.com',
            direccion: 'Calle 123 #45-67'
          )
          expect(result).to eq(saved_cliente)
        }.not_to raise_error
      end
    end
  end
end
