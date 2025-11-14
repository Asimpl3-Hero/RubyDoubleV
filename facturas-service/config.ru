require_relative 'config/environment'
require_relative 'app/interfaces/http/facturas_controller'

# Mount controllers
map '/' do
  run FacturasController
end
