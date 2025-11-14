# Controller Layer (MVC) - Handles HTTP requests and responses

require 'sinatra/base'
require 'json'
require_relative '../application/use_cases/create_cliente'
require_relative '../application/use_cases/get_cliente'
require_relative '../application/use_cases/list_clientes'
require_relative '../infrastructure/persistence/active_record_cliente_repository'

class ClientesController < Sinatra::Base
  configure do
    set :show_exceptions, false
    # Set app root to /app (Docker WORKDIR)
    # From /app/app/controllers/clientes_controller.rb go up 2 levels to /app
    set :root, File.expand_path('../..', __dir__)
    set :public_folder, File.join(settings.root, 'public')
    enable :static
  end

  before do
    content_type :json
  end

  # Root endpoint - Service information
  get '/' do
    status 200
    {
      success: true,
      service: 'clientes-service',
      version: '1.0.0',
      status: 'running',
      description: 'API REST para la gestión de clientes del sistema FactuMarket',
      timestamp: Time.now.utc.iso8601,
      endpoints: {
        health: '/health',
        docs: '/docs',
        api_docs: '/api-docs',
        clientes: {
          create: 'POST /clientes',
          get: 'GET /clientes/:id',
          list: 'GET /clientes'
        }
      },
      links: {
        documentation: '/docs',
        openapi_spec: '/api-docs'
      }
    }.to_json
  end

  # POST /clientes - Create a new cliente
  post '/clientes' do
    data = JSON.parse(request.body.read)

    use_case = Application::UseCases::CreateCliente.new(
      cliente_repository: repository,
      auditoria_service_url: auditoria_url
    )

    cliente = use_case.execute(
      nombre: data['nombre'],
      identificacion: data['identificacion'],
      correo: data['correo'],
      direccion: data['direccion']
    )

    status 201
    {
      success: true,
      message: 'Cliente creado exitosamente',
      data: cliente.to_h
    }.to_json
  rescue ArgumentError => e
    status 400
    { success: false, error: e.message }.to_json
  rescue StandardError => e
    status 500
    { success: false, error: e.message }.to_json
  end

  # GET /clientes/:id - Get cliente by ID
  get '/clientes/:id' do
    use_case = Application::UseCases::GetCliente.new(
      cliente_repository: repository,
      auditoria_service_url: auditoria_url
    )

    cliente = use_case.execute(id: params[:id].to_i)

    status 200
    {
      success: true,
      data: cliente.to_h
    }.to_json
  rescue StandardError => e
    status 404
    { success: false, error: e.message }.to_json
  end

  # GET /clientes - List all clientes
  get '/clientes' do
    use_case = Application::UseCases::ListClientes.new(
      cliente_repository: repository,
      auditoria_service_url: auditoria_url
    )

    clientes = use_case.execute

    status 200
    {
      success: true,
      data: clientes.map(&:to_h),
      count: clientes.count
    }.to_json
  rescue StandardError => e
    status 500
    { success: false, error: e.message }.to_json
  end

  # Health check endpoint
  get '/health' do
    status 200
    {
      success: true,
      service: 'clientes-service',
      status: 'running',
      timestamp: Time.now.utc.iso8601
    }.to_json
  end

  # OpenAPI specification endpoint
  get '/api-docs' do
    content_type 'application/yaml'

    # Try multiple locations to find openapi.yaml (production-safe)
    possible_paths = [
      '/app/public/openapi.yaml',                                  # Docker WORKDIR (production)
      File.join(settings.root, 'public', 'openapi.yaml'),          # Sinatra root
      File.expand_path('../../../public/openapi.yaml', __FILE__)   # Relative to this file
    ]

    # Add Dir.pwd path only if accessible (may fail in production)
    begin
      possible_paths << File.join(Dir.pwd, 'public', 'openapi.yaml')
    rescue Errno::ENOENT, SystemCallError
      # Ignore if pwd is not accessible
    end

    openapi_path = possible_paths.find { |path| File.exist?(path) }

    unless openapi_path
      halt 404, {
        error: "OpenAPI spec not found",
        searched_paths: possible_paths,
        settings_root: settings.root.to_s
      }.to_json
    end

    File.read(openapi_path)
  rescue StandardError => e
    status 500
    { error: "Failed to read OpenAPI spec: #{e.message}" }.to_json
  end

  # Swagger UI endpoint
  get '/docs' do
    content_type :html
    <<~HTML
      <!DOCTYPE html>
      <html lang="es">
      <head>
        <meta charset="UTF-8">
        <title>Clientes Service API - Swagger UI</title>
        <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@5.10.3/swagger-ui.css">
        <style>
          body { margin: 0; padding: 0; }
        </style>
      </head>
      <body>
        <div id="swagger-ui"></div>
        <script src="https://unpkg.com/swagger-ui-dist@5.10.3/swagger-ui-bundle.js"></script>
        <script src="https://unpkg.com/swagger-ui-dist@5.10.3/swagger-ui-standalone-preset.js"></script>
        <script>
          window.onload = function() {
            SwaggerUIBundle({
              url: "/api-docs",
              dom_id: '#swagger-ui',
              deepLinking: true,
              presets: [
                SwaggerUIBundle.presets.apis,
                SwaggerUIStandalonePreset
              ],
              plugins: [
                SwaggerUIBundle.plugins.DownloadUrl
              ],
              layout: "StandaloneLayout"
            });
          };
        </script>
      </body>
      </html>
    HTML
  end

  private

  def repository
    @repository ||= Infrastructure::Persistence::ActiveRecordClienteRepository.new
  end

  def auditoria_url
    ENV['AUDITORIA_SERVICE_URL'] || 'http://localhost:4003'
  end
end
