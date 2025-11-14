require_relative 'config/environment'
require_relative 'app/interfaces/http/clientes_controller'

# Mount controllers
map '/' do
  run ClientesController
end
