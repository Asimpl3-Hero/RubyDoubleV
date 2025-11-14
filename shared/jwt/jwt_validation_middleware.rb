require_relative 'service_jwt'
require_relative 'jwt_logger'

module JwtValidationMiddleware
  class Validator
    def initialize(app, options = {})
      @app = app
      @exempt_paths = options[:exempt_paths] || ['/health', '/docs', '/api-docs']
    end

    def call(env)
      request = Rack::Request.new(env)

      if exempt_path?(request.path_info)
        return @app.call(env)
      end

      auth_header = env['HTTP_AUTHORIZATION']

      unless auth_header
        return unauthorized_response('Token requerido')
      end

      token = auth_header.split(' ').last
      result = ServiceJWT.validate(token)

      service_name = ENV['SERVICE_NAME'] || 'unknown-service'

      # Log validation result
      JwtLogger.log_token_validation(
        issuer: result[:issuer] || 'unknown',
        service: service_name,
        path: request.path_info,
        success: result[:valid],
        error: result[:error]
      )

      if result[:valid]
        env['jwt.issuer'] = result[:issuer]
        env['jwt.claims'] = result[:claims]
        @app.call(env)
      else
        unauthorized_response(result[:error])
      end
    end

    private

    def exempt_path?(path)
      @exempt_paths.any? { |exempt| path.start_with?(exempt) }
    end

    def unauthorized_response(message)
      [
        401,
        { 'Content-Type' => 'application/json' },
        [{ success: false, error: message }.to_json]
      ]
    end
  end
end
