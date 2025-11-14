# Servicio de Facturas

Microservicio responsable de la creación y gestión de facturas electrónicas del sistema FactuMarket.

## Propósito

Gestiona el ciclo de vida completo de las facturas electrónicas, permitiendo:
- Crear facturas con validación de cliente existente
- Generar números de factura únicos automáticamente
- Consultar facturas individuales
- Listar facturas con filtrado por rango de fechas
- Aplicar validaciones de negocio (monto positivo, fecha válida)
- Registrar eventos de auditoría

## Tecnología

- **Arquitectura**: Clean Architecture + MVC
- **Base de datos**: SQLite (desarrollo) / Oracle (producción)
- **Framework**: Sinatra
- **ORM**: ActiveRecord
- **Puerto**: 4002

## API REST

### POST /facturas
Crea una nueva factura electrónica.

**Request:**
```json
{
  "cliente_id": 1,
  "fecha_emision": "2025-01-13",
  "monto": 1500000,
  "items": [
    {
      "descripcion": "Laptop Dell",
      "cantidad": 1,
      "precio_unitario": 1500000,
      "subtotal": 1500000
    }
  ]
}
```

**Validaciones:**
- Cliente debe existir (valida con Clientes Service)
- Monto debe ser mayor a 0
- Fecha de emisión no puede ser futura
- Items es opcional

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Factura creada exitosamente",
  "data": {
    "id": 1,
    "cliente_id": 1,
    "numero_factura": "F-20250113-A1B2C3D4",
    "fecha_emision": "2025-01-13",
    "monto": 1500000.0,
    "estado": "EMITIDA",
    "items": [...],
    "created_at": "2025-01-13T10:35:00Z",
    "updated_at": "2025-01-13T10:35:00Z"
  }
}
```

**Errores:**
- `400`: Datos inválidos (monto negativo, fecha futura)
- `422`: Cliente no existe
- `503`: Servicio de Clientes no disponible

### GET /facturas/:id
Consulta una factura específica.

### GET /facturas
Lista facturas con filtro opcional por rango de fechas.

**Parámetros:**
- `fechaInicio`: Fecha inicio (formato: YYYY-MM-DD)
- `fechaFin`: Fecha fin (formato: YYYY-MM-DD)

**Ejemplo:**
```bash
GET /facturas?fechaInicio=2025-01-01&fechaFin=2025-01-31
```

### GET /health
Health check del servicio.

## Estructura del Proyecto

```
facturas-service/
├── app/
│   ├── controllers/                    # API REST con Sinatra
│   │   └── facturas_controller.rb
│   ├── models/                        # Modelos ActiveRecord
│   │   └── factura_model.rb
│   ├── domain/                        # Capa de dominio
│   │   ├── entities/
│   │   │   └── factura.rb            # Entidad con reglas de negocio
│   │   ├── repositories/
│   │   │   └── factura_repository.rb  # Interface del repositorio
│   │   └── services/
│   │       └── cliente_validator.rb   # Validador de cliente
│   ├── application/                   # Casos de uso
│   │   └── use_cases/
│   │       ├── create_factura.rb
│   │       ├── get_factura.rb
│   │       └── list_facturas.rb
│   └── infrastructure/                # Adaptadores
│       └── persistence/
│           └── active_record_factura_repository.rb
├── config/                           # Configuración
│   ├── database.yml
│   └── environment.rb
├── db/                              # Base de datos
│   ├── migrate/
│   │   └── 001_create_facturas.rb
│   └── schema.rb
├── spec/                            # Tests con RSpec
│   ├── spec_helper.rb
│   ├── integration_spec_helper.rb
│   ├── domain/
│   ├── application/
│   ├── infrastructure/
│   └── integration/
├── .env.example
├── config.ru
├── Gemfile
└── README.md
```

### Descripción de Carpetas

- **app/controllers**: Controladores REST que exponen la API HTTP
- **app/models**: Modelos ActiveRecord para persistencia
- **app/domain/entities**: Entidades de dominio con reglas de negocio
- **app/domain/repositories**: Interfaces de repositorios
- **app/domain/services**: Servicios de dominio (ej: validación de cliente)
- **app/application/use_cases**: Casos de uso que orquestan la lógica
- **app/infrastructure/persistence**: Implementaciones de repositorios
- **config**: Configuración de base de datos y entorno
- **db/migrate**: Migraciones de base de datos
- **spec**: Tests organizados por capa arquitectónica

## Instalación y Ejecución

### Requisitos
- Ruby >= 2.7.0
- Bundler
- SQLite3 (desarrollo) u Oracle (producción)
- **Clientes Service** corriendo en puerto 4001 (requerido)

### Setup

```bash
# Instalar dependencias
bundle install

# Configurar variables de entorno
cp .env.example .env

# Editar .env con URLs de servicios
# CLIENTES_SERVICE_URL=http://localhost:4001
# AUDITORIA_SERVICE_URL=http://localhost:4003

# Ejecutar migraciones
bundle exec rake db:migrate

# Iniciar servidor
bundle exec puma config.ru -p 4002
```

### Con Docker

```bash
docker-compose up facturas-service
```

## Testing

```bash
# Ejecutar todos los tests
bundle exec rspec

# Tests con cobertura
bundle exec rspec --format documentation

# Tests de dominio únicamente
bundle exec rspec spec/domain
```

## Variables de Entorno

```bash
PORT=4002
DATABASE_URL=sqlite3:db/facturas.sqlite3
CLIENTES_SERVICE_URL=http://localhost:4001    # REQUERIDO
AUDITORIA_SERVICE_URL=http://localhost:4003
RACK_ENV=development
```

## Base de Datos

### Tabla: facturas

| Campo          | Tipo              | Descripción                |
|----------------|-------------------|----------------------------|
| id             | INTEGER           | Primary Key                |
| cliente_id     | INTEGER           | FK a clientes (índice)     |
| numero_factura | VARCHAR(50)       | Único, generado auto       |
| fecha_emision  | DATE              | Fecha de emisión (índice)  |
| monto          | DECIMAL(10,2)     | Monto total                |
| estado         | VARCHAR(20)       | EMITIDA, ANULADA, etc.     |
| items          | TEXT/JSON         | Items serializado          |
| created_at     | TIMESTAMP         | Fecha de creación          |
| updated_at     | TIMESTAMP         | Última actualización       |

### Índices
- `cliente_id`: Para consultas por cliente
- `fecha_emision`: Para consultas por fecha
- `numero_factura`: UNIQUE

### Formato Número de Factura
Generado automáticamente: `F-YYYYMMDD-HEXCODE`

Ejemplo: `F-20250113-A1B2C3D4`

## Validaciones de Negocio

### Cliente Válido
Antes de crear una factura, se valida que el cliente exista consultando al Clientes Service.

```ruby
# Validación síncrona con timeout de 5s
unless cliente_exists?(cliente_id)
  raise "Cliente con ID #{cliente_id} no existe"
end
```

### Monto Positivo
```ruby
raise ArgumentError unless monto > 0
```

### Fecha de Emisión
```ruby
# No puede ser futura
fecha_emision <= Date.today
```

## Integración

### Servicio de Clientes
Comunicación **síncrona** para validar cliente.

**URL**: http://localhost:4001/clientes/:id
**Timeout**: 5 segundos
**Tipo**: GET request
**Comportamiento**: Si falla, no se crea la factura

### Servicio de Auditoría
Comunicación **asíncrona** (fire-and-forget).

**URL**: http://localhost:4003/auditoria
**Timeout**: 2 segundos
**Eventos registrados**:
- CREATE: Factura creada
- READ: Factura consultada
- LIST: Listado de facturas
- ERROR: Error en operación

**Comportamiento**: Si falla, solo registra warning sin afectar operación

## Clean Architecture

El servicio sigue Clean Architecture con las siguientes capas:

**Domain Layer**:
- Entidades: `Factura` con reglas de negocio
- Servicios: `ClienteValidator` para validar cliente
- Repositorios: Interface `FacturaRepository`

**Application Layer**:
- Casos de uso que orquestan creación, consulta y listado

**Infrastructure Layer**:
- Repositorio con ActiveRecord
- Cliente HTTP para comunicación con otros servicios

**Presentation Layer**:
- Controller Sinatra que expone API REST
