# Domain Service - Validates if a cliente exists in the Clientes microservice

require 'httparty'

module Domain
  module Services
    class ClienteValidator
      def initialize(clientes_service_url:)
        @clientes_service_url = clientes_service_url
      end

      def cliente_exists?(cliente_id)
        response = HTTParty.get(
          "#{@clientes_service_url}/clientes/#{cliente_id}",
          timeout: 5
        )

        response.success? && JSON.parse(response.body)['success']
      rescue StandardError => e
        puts "Error validating cliente: #{e.message}"
        false
      end

      def get_cliente(cliente_id)
        response = HTTParty.get(
          "#{@clientes_service_url}/clientes/#{cliente_id}",
          timeout: 5
        )

        if response.success?
          JSON.parse(response.body)['data']
        else
          nil
        end
      rescue StandardError => e
        puts "Error getting cliente: #{e.message}"
        nil
      end
    end
  end
end
