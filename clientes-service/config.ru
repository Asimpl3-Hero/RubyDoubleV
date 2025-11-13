require_relative 'config/environment'
require_relative 'app/controllers/clientes_controller'

# Mount controllers
map '/' do
  run ClientesController
end
