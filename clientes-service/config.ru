require_relative 'config/environment'
require_relative '../shared/jwt_validation_middleware'
require_relative 'app/interfaces/http/clientes_controller'

# JWT validation middleware
use JwtValidationMiddleware::Validator, exempt_paths: ['/health', '/docs', '/api-docs']

# Mount controllers
map '/' do
  run ClientesController
end
