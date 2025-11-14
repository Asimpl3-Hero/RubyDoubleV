require 'httparty'
require_relative 'service_jwt'

module AuthenticatedHttpClient
  class Client
    def self.get(url, options = {})
      request(:get, url, options)
    end

    def self.post(url, options = {})
      request(:post, url, options)
    end

    private

    def self.request(method, url, options = {})
      token = ServiceJWT.generate_for_current_service

      headers = (options[:headers] || {}).merge({
        'Authorization' => "Bearer #{token}"
      })

      HTTParty.send(method, url, options.merge(headers: headers))
    rescue StandardError => e
      raise "HTTP request failed: #{e.message}"
    end
  end
end
