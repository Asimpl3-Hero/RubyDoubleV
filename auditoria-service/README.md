# Servicio de Auditoría

Microservicio responsable del registro y consulta de eventos de auditoría del sistema FactuMarket.

## Propósito

Registro centralizado de eventos para todo el sistema que permite:
- Registrar eventos de microservicios (CREATE, READ, UPDATE, DELETE, LIST)
- Consultar eventos por entidad, acción o estado
- Proporcionar trazabilidad completa del sistema
- Detectar errores y patrones de uso

## Tecnología

- **Patrón**: MVC
- **Base de datos**: MongoDB
- **Framework**: Sinatra
- **Puerto**: 4003

## API REST

### POST /auditoria
Registra un nuevo evento de auditoría.

**Request:**
```json
{
  "entity_type": "factura",
  "entity_id": 1,
  "action": "CREATE",
  "details": "Factura F-20250113-ABC123 creada",
  "status": "SUCCESS",
  "timestamp": "2025-01-13T10:35:00Z"
}
```

**Campos:**
- `entity_type` (string): cliente, factura
- `entity_id` (integer, opcional): ID de la entidad
- `action` (string): CREATE, READ, UPDATE, DELETE, LIST
- `details` (string): Descripción del evento
- `status` (string): SUCCESS, ERROR
- `timestamp` (string): ISO 8601

### GET /auditoria/:factura_id
Consulta todos los eventos de una factura.

### GET /auditoria/cliente/:cliente_id
Consulta todos los eventos de un cliente.

### GET /auditoria
Lista eventos con filtros opcionales.

**Parámetros:**
- `action`: Filtrar por acción
- `status`: Filtrar por estado
- `limit`: Número máximo de resultados (default: 100)

### GET /health
Health check del servicio.

## Estructura del Proyecto

```
auditoria-service/
├── app/
│   ├── controllers/          # API REST con Sinatra
│   │   └── auditoria_controller.rb
│   ├── models/              # Modelos de datos
│   │   └── audit_event.rb
│   ├── application/         # Casos de uso
│   │   └── use_cases/
│   ├── domain/             # Entidades de dominio
│   │   └── entities/
│   └── infrastructure/     # Persistencia y adaptadores
│       └── persistence/
│           └── mongo_audit_repository.rb
├── config/                 # Configuración del servicio
│   └── environment.rb
├── spec/                   # Tests con RSpec
│   ├── spec_helper.rb
│   ├── domain/
│   ├── application/
│   ├── infrastructure/
│   └── integration/
├── .env.example           # Variables de entorno ejemplo
├── config.ru             # Configuración Rack
├── Gemfile              # Dependencias Ruby
└── README.md
```

### Descripción de Carpetas

- **app/controllers**: Controladores REST que manejan las peticiones HTTP
- **app/models**: Modelos que representan eventos de auditoría
- **app/application/use_cases**: Lógica de aplicación y orquestación
- **app/domain/entities**: Entidades de dominio con reglas de negocio
- **app/infrastructure/persistence**: Implementación de repositorios y acceso a MongoDB
- **config**: Configuración del entorno y base de datos
- **spec**: Tests unitarios e integración organizados por capa

## Instalación y Ejecución

### Requisitos
- Ruby >= 2.7.0
- MongoDB >= 5.0

### Setup

```bash
# Instalar dependencias
bundle install

# Configurar variables de entorno
cp .env.example .env

# Editar .env con la URL de MongoDB
# MONGO_URL=localhost:27017
# MONGO_DATABASE=auditoria_db

# Iniciar servidor
bundle exec puma config.ru -p 4003
```

### Con Docker

```bash
docker-compose up auditoria-service
```

## Testing

```bash
# Ejecutar todos los tests
bundle exec rspec

# Tests con cobertura
bundle exec rspec --format documentation
```

## Variables de Entorno

```bash
PORT=4003
MONGO_URL=localhost:27017
MONGO_DATABASE=auditoria_db
RACK_ENV=development
```

## Base de Datos MongoDB

### Collection: audit_events

**Estructura:**
```javascript
{
  entity_type: String,     // cliente, factura
  entity_id: Integer,      // ID de la entidad (opcional)
  action: String,          // CREATE, READ, UPDATE, DELETE, LIST
  details: String,         // Descripción del evento
  status: String,          // SUCCESS, ERROR
  timestamp: String,       // ISO 8601
  created_at: Date        // Fecha de creación
}
```

### Índices
```javascript
db.audit_events.createIndex({ entity_type: 1, entity_id: 1 })
db.audit_events.createIndex({ created_at: -1 })
db.audit_events.createIndex({ action: 1 })
db.audit_events.createIndex({ status: 1 })
```

## Integración

Este servicio recibe eventos de forma asíncrona (fire-and-forget) desde:
- **Clientes Service** (Puerto 4001)
- **Facturas Service** (Puerto 4002)

Si el servicio de auditoría falla, no afecta la operación principal de los otros servicios.
