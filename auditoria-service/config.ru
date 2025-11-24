require_relative 'config/environment'
require_relative './shared/jwt/service_jwt'
require_relative 'app/interfaces/http/auditoria_controller'
require 'rack/cors'

# CORS middleware for Swagger UI
use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end

# Mount controllers
map '/' do
  run AuditoriaController
end
