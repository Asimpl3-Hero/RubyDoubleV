require_relative 'config/environment'
require_relative 'app/controllers/auditoria_controller'

# Mount controllers
map '/' do
  run AuditoriaController
end
