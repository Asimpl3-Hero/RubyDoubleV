# Controller Layer (MVC) - Handles HTTP requests for audit events

require 'sinatra/base'
require 'json'
require_relative '../infrastructure/persistence/mongo_audit_repository'
require_relative '../models/audit_event'

class AuditoriaController < Sinatra::Base
  configure do
    set :show_exceptions, false
  end

  before do
    content_type :json
  end

  # POST /auditoria - Create a new audit event
  post '/auditoria' do
    data = JSON.parse(request.body.read)

    audit_event = AuditEvent.new(
      entity_type: data['entity_type'],
      entity_id: data['entity_id'],
      action: data['action'],
      details: data['details'],
      status: data['status'],
      timestamp: data['timestamp']
    )

    saved_event = repository.save(audit_event)

    status 201
    {
      success: true,
      message: 'Evento de auditoría registrado',
      data: saved_event.to_h
    }.to_json
  rescue StandardError => e
    status 500
    { success: false, error: e.message }.to_json
  end

  # GET /auditoria/:factura_id - Get audit events for a specific factura
  get '/auditoria/:factura_id' do
    events = repository.find_by_factura_id(params[:factura_id].to_i)

    status 200
    {
      success: true,
      data: events.map(&:to_h),
      count: events.count
    }.to_json
  rescue StandardError => e
    status 500
    { success: false, error: e.message }.to_json
  end

  # GET /auditoria/cliente/:cliente_id - Get audit events for a specific cliente
  get '/auditoria/cliente/:cliente_id' do
    events = repository.find_by_cliente_id(params[:cliente_id].to_i)

    status 200
    {
      success: true,
      data: events.map(&:to_h),
      count: events.count
    }.to_json
  rescue StandardError => e
    status 500
    { success: false, error: e.message }.to_json
  end

  # GET /auditoria - Get all audit events (paginated)
  get '/auditoria' do
    limit = (params['limit'] || 100).to_i

    events = if params['action']
               repository.find_by_action(action: params['action'], limit: limit)
             elsif params['status']
               repository.find_by_status(status: params['status'], limit: limit)
             else
               repository.find_all(limit: limit)
             end

    status 200
    {
      success: true,
      data: events.map(&:to_h),
      count: events.count
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
      service: 'auditoria-service',
      status: 'running',
      timestamp: Time.now.utc.iso8601
    }.to_json
  end

  # OpenAPI specification endpoint
  get '/api-docs' do
    content_type 'application/yaml'
    File.read(File.join(settings.root, '..', '..', 'public', 'openapi.yaml'))
  end

  # Swagger UI endpoint
  get '/docs' do
    content_type :html
    <<~HTML
      <!DOCTYPE html>
      <html lang="es">
      <head>
        <meta charset="UTF-8">
        <title>Auditoría Service API - Swagger UI</title>
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
    @repository ||= Infrastructure::Persistence::MongoAuditRepository.new(mongo_client)
  end

  def mongo_client
    @mongo_client ||= Mongo::Client.new(
      [mongo_url],
      database: mongo_database
    )
  end

  def mongo_url
    ENV['MONGO_URL'] || 'localhost:27017'
  end

  def mongo_database
    ENV['MONGO_DATABASE'] || 'auditoria_db'
  end
end
