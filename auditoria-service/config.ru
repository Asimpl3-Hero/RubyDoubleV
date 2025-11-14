require_relative 'config/environment'
require_relative 'app/interfaces/http/auditoria_controller'

# Mount controllers
map '/' do
  run AuditoriaController
end
