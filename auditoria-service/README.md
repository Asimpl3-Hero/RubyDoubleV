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
│   ├── interfaces/             # Capa de Interfaces (Presentación)
│   │   └── http/              # Controladores HTTP REST
│   │       └── auditoria_controller.rb
│   ├── application/           # Capa de Aplicación
│   │   └── use_cases/        # Casos de uso del negocio
│   ├── domain/               # Capa de Dominio (Núcleo)
│   │   ├── entities/        # Entidades con lógica de negocio
│   │   └── repositories/    # Interfaces de repositorios
│   └── infrastructure/       # Capa de Infraestructura
│       └── persistence/     # Implementaciones de persistencia (MongoDB)
├── config/                   # Configuración del servicio
│   └── environment.rb
├── spec/                     # Tests con RSpec
│   ├── spec_helper.rb
│   ├── interfaces/          # Tests de controladores HTTP
│   │   └── http/
│   ├── domain/              # Tests de entidades
│   ├── application/         # Tests de casos de uso
│   └── infrastructure/      # Tests de persistencia
├── public/                   # Assets públicos
│   └── openapi.yaml         # Documentación OpenAPI 3.1.0
├── .env.example             # Variables de entorno ejemplo
├── config.ru               # Configuración Rack
├── Gemfile                # Dependencias Ruby
└── README.md
```

### Descripción de Capas (Clean Architecture)

#### 🎯 Capa de Interfaces (app/interfaces/)
- **http/**: Controladores REST que manejan peticiones HTTP con Sinatra
- Responsabilidad: Adaptadores de entrada (HTTP, CLI, etc.)
- Dependencias: → Application Layer

#### 💼 Capa de Aplicación (app/application/)
- **use_cases/**: Orquestación de lógica de negocio
- Responsabilidad: Casos de uso y flujos de la aplicación
- Dependencias: → Domain Layer

#### 🏛️ Capa de Dominio (app/domain/)
- **entities/**: Entidades con reglas de negocio (AuditEvent)
- **repositories/**: Interfaces/contratos de repositorios
- Responsabilidad: Lógica de negocio pura, sin dependencias externas
- Dependencias: Ninguna (núcleo independiente)

#### 🔧 Capa de Infraestructura (app/infrastructure/)
- **persistence/**: Implementación de repositorios (MongoDB)
- Responsabilidad: Detalles técnicos (DB, APIs externas, etc.)
- Dependencias: → Domain Layer (implementa interfaces)

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
