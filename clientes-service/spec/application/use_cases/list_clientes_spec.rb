require 'spec_helper'
require_relative '../../../app/application/use_cases/list_clientes'
require_relative '../../../app/domain/repositories/cliente_repository'

RSpec.describe Application::UseCases::ListClientes do
  let(:repository) { instance_double(Domain::Repositories::ClienteRepository) }
  let(:auditoria_service_url) { 'http://localhost:4003' }
  let(:use_case) { described_class.new(cliente_repository: repository, auditoria_service_url: auditoria_service_url) }

  describe '#execute' do
    context 'when clientes exist' do
      it 'returns all clientes' do
        clientes = [
          Domain::Entities::Cliente.new(
            id: 1,
            nombre: 'Empresa ABC S.A.',
            identificacion: '900123456',
            correo: 'contacto@abc.com',
            direccion: 'Calle 123'
          ),
          Domain::Entities::Cliente.new(
            id: 2,
            nombre: 'Empresa XYZ Ltda.',
            identificacion: '900654321',
            correo: 'contacto@xyz.com',
            direccion: 'Calle 456'
          )
        ]

        expect(repository).to receive(:find_all).and_return(clientes)
        allow(HTTParty).to receive(:post).and_return(double(success?: true))

        result = use_case.execute

        expect(result).to eq(clientes)
        expect(result.size).to eq(2)
      end

      it 'registers a success audit event' do
        clientes = [
          Domain::Entities::Cliente.new(
            id: 1,
            nombre: 'Empresa ABC S.A.',
            identificacion: '900123456',
            correo: 'contacto@abc.com',
            direccion: 'Calle 123'
          )
        ]

        allow(repository).to receive(:find_all).and_return(clientes)

        expect(HTTParty).to receive(:post).with(
          "#{auditoria_service_url}/auditoria",
          hash_including(
            body: /LIST/,
            headers: { 'Content-Type' => 'application/json' }
          )
        )

        use_case.execute
      end
    end

    context 'when no clientes exist' do
      it 'returns empty array' do
        expect(repository).to receive(:find_all).and_return([])
        allow(HTTParty).to receive(:post).and_return(double(success?: true))

        result = use_case.execute

        expect(result).to eq([])
        expect(result).to be_empty
      end
    end

    context 'when repository fails' do
      it 'registers an error audit event and raises exception' do
        allow(repository).to receive(:find_all).and_raise(StandardError, 'Database connection failed')

        expect(HTTParty).to receive(:post).with(
          "#{auditoria_service_url}/auditoria",
          hash_including(body: /ERROR/)
        )

        expect {
          use_case.execute
        }.to raise_error(StandardError, 'Database connection failed')
      end
    end

    context 'when audit service fails' do
      it 'continues execution and does not raise error' do
        clientes = []

        allow(repository).to receive(:find_all).and_return(clientes)
        allow(HTTParty).to receive(:post).and_raise(StandardError, 'Audit service down')

        expect {
          result = use_case.execute
          expect(result).to eq(clientes)
        }.not_to raise_error
      end
    end
  end
end
