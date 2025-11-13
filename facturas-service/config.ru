require_relative 'config/environment'
require_relative 'app/controllers/facturas_controller'

# Mount controllers
map '/' do
  run FacturasController
end
