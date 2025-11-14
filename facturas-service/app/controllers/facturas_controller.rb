# Controller Layer (MVC) - Handles HTTP requests and responses

require 'sinatra/base'
require 'json'
require_relative '../application/use_cases/create_factura'
require_relative '../application/use_cases/get_factura'
require_relative '../application/use_cases/list_facturas'
require_relative '../infrastructure/persistence/active_record_factura_repository'

class FacturasController < Sinatra::Base
  configure do
    set :show_exceptions, false

    # Find app root intelligently by looking for config.ru
    # This works regardless of directory structure changes
    app_root = ENV['APP_ROOT'] || begin
      current_dir = __dir__
      # Traverse up until we find config.ru or reach root
      while current_dir != '/' && !File.exist?(File.join(current_dir, 'config.ru'))
        current_dir = File.dirname(current_dir)
      end
      current_dir
    end

    set :root, app_root
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
      service: 'facturas-service',
      version: '1.0.0',
      status: 'running',
      description: 'API REST para la gestión de facturas electrónicas del sistema FactuMarket',
      timestamp: Time.now.utc.iso8601,
      endpoints: {
        health: '/health',
        docs: '/docs',
        api_docs: '/api-docs',
        facturas: {
          create: 'POST /facturas',
          get: 'GET /facturas/:id',
          list: 'GET /facturas',
          list_by_date: 'GET /facturas?fechaInicio=YYYY-MM-DD&fechaFin=YYYY-MM-DD'
        }
      },
      links: {
        documentation: '/docs',
        openapi_spec: '/api-docs'
      }
    }.to_json
  end

  # POST /facturas - Create a new factura
  post '/facturas' do
    data = JSON.parse(request.body.read)

    use_case = Application::UseCases::CreateFactura.new(
      factura_repository: repository,
      clientes_service_url: clientes_url,
      auditoria_service_url: auditoria_url
    )

    factura = use_case.execute(
      cliente_id: data['cliente_id'],
      fecha_emision: data['fecha_emision'],
      monto: data['monto'],
      items: data['items'] || []
    )

    status 201
    {
      success: true,
      message: 'Factura creada exitosamente',
      data: factura.to_h
    }.to_json
  rescue ArgumentError => e
    status 400
    { success: false, error: e.message }.to_json
  rescue StandardError => e
    # Check if it's an infrastructure error (timeout, connection issues, etc.)
    if e.message.match?(/timeout|connection|unavailable|timed out|execution expired/i)
      status 503
      { success: false, error: e.message }.to_json
    else
      # Business logic errors (like "Cliente no existe") return 422
      status 422
      { success: false, error: e.message }.to_json
    end
  end

  # GET /facturas/:id - Get factura by ID
  get '/facturas/:id' do
    use_case = Application::UseCases::GetFactura.new(
      factura_repository: repository,
      auditoria_service_url: auditoria_url
    )

    factura = use_case.execute(id: params[:id].to_i)

    status 200
    {
      success: true,
      data: factura.to_h
    }.to_json
  rescue StandardError => e
    status 404
    { success: false, error: e.message }.to_json
  end

  # GET /facturas - List facturas with optional date range filter
  get '/facturas' do
    use_case = Application::UseCases::ListFacturas.new(
      factura_repository: repository,
      auditoria_service_url: auditoria_url
    )

    facturas = use_case.execute(
      fecha_inicio: params['fechaInicio'],
      fecha_fin: params['fechaFin']
    )

    status 200
    {
      success: true,
      data: facturas.map(&:to_h),
      count: facturas.count
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
      service: 'facturas-service',
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
        <title>Facturas Service API - Swagger UI</title>
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
    @repository ||= Infrastructure::Persistence::ActiveRecordFacturaRepository.new
  end

  def clientes_url
    ENV['CLIENTES_SERVICE_URL'] || 'http://localhost:4001'
  end

  def auditoria_url
    ENV['AUDITORIA_SERVICE_URL'] || 'http://localhost:4003'
  end
end
