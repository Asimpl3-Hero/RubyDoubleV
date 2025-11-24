require_relative 'config/environment'
require_relative './shared/jwt/jwt_validation_middleware'
require_relative './shared/jwt/service_jwt'
require_relative 'app/interfaces/http/facturas_controller'
require 'rack/cors'

# CORS middleware for Swagger UI
use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end

# JWT validation middleware
use JwtValidationMiddleware::Validator, exempt_paths: ['/health', '/docs', '/api-docs', '/auth/token']

# Mount controllers
map '/' do
  run FacturasController
end
