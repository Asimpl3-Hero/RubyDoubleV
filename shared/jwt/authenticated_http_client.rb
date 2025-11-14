require 'httparty'
require_relative 'service_jwt'
require_relative 'jwt_logger'

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
      from_service = ENV['SERVICE_NAME'] || 'unknown-service'

      # Extract target service from URL
      to_service = extract_service_from_url(url)

      headers = (options[:headers] || {}).merge({
        'Authorization' => "Bearer #{token}"
      })

      response = HTTParty.send(method, url, options.merge(headers: headers))

      # Log service communication
      JwtLogger.log_service_communication(
        from: from_service,
        to: to_service,
        endpoint: url,
        method: method.to_s.upcase,
        success: response.success?
      )

      response
    rescue StandardError => e
      # Log failed communication
      JwtLogger.log_service_communication(
        from: from_service,
        to: to_service || 'unknown',
        endpoint: url,
        method: method.to_s.upcase,
        success: false
      )
      raise "HTTP request failed: #{e.message}"
    end

    def self.extract_service_from_url(url)
      # Extract service name from URL like http://clientes-service:4001/...
      match = url.match(/\/\/([^:\/]+)/)
      match ? match[1] : 'unknown-service'
    end
  end
end
