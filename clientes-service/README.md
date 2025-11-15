# Servicio de Clientes

Microservicio responsable de la gestión completa de clientes del sistema FactuMarket.

## Propósito

Gestiona toda la información relacionada con clientes, permitiendo:
- Registrar nuevos clientes (personas naturales o jurídicas)
- Consultar información de clientes existentes
- Listar todos los clientes registrados
- Validar unicidad de identificación
- Registrar eventos de auditoría por cada operación

## Tecnología

- **Arquitectura**: Clean Architecture + MVC
- **Base de datos**: SQLite3
- **Framework**: Sinatra
- **ORM**: ActiveRecord
- **Puerto**: 4001

## API REST

### POST /clientes
Crea un nuevo cliente.

**Request:**
```json
{
  "nombre": "Empresa ABC S.A.",
  "identificacion": "900123456",
  "correo": "contacto@empresaabc.com",
  "direccion": "Calle 123 #45-67, Bogotá"
}
```

**Validaciones:**
- Nombre requerido
- Identificación única requerida
- Correo con formato válido
- Dirección requerida

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Cliente creado exitosamente",
  "data": {
    "id": 1,
    "nombre": "Empresa ABC S.A.",
    "identificacion": "900123456",
    "correo": "contacto@empresaabc.com",
    "direccion": "Calle 123 #45-67, Bogotá",
    "created_at": "2025-01-13T10:30:00Z",
    "updated_at": "2025-01-13T10:30:00Z"
  }
}
```

### GET /clientes/:id
Consulta un cliente específico.

### GET /clientes
Lista todos los clientes registrados.

### GET /health
Health check del servicio.

## Estructura del Proyecto

```
clientes-service/
├── app/
│   ├── interfaces/                    # Capa de Interfaces (Presentación)
│   │   └── http/                     # Controladores HTTP REST
│   │       └── clientes_controller.rb
│   ├── application/                   # Capa de Aplicación
│   │   └── use_cases/                # Casos de uso del negocio
│   │       ├── create_cliente.rb
│   │       ├── get_cliente.rb
│   │       └── list_clientes.rb
│   ├── domain/                        # Capa de Dominio (Núcleo)
│   │   ├── entities/                 # Entidades con lógica de negocio
│   │   │   └── cliente.rb
│   │   └── repositories/             # Interfaces de repositorios
│   │       └── cliente_repository.rb
│   └── infrastructure/                # Capa de Infraestructura
│       └── persistence/              # Implementaciones de persistencia
│           ├── active_record_cliente_repository.rb
│           └── cliente_model.rb      # Modelo ActiveRecord
├── config/                            # Configuración
│   ├── database.yml
│   └── environment.rb
├── db/                                # Base de datos
│   ├── migrate/
│   │   └── 001_create_clientes.rb
│   └── schema.rb
├── spec/                              # Tests con RSpec
│   ├── spec_helper.rb
│   ├── integration_spec_helper.rb
│   ├── interfaces/                   # Tests de controladores HTTP
│   │   └── http/
│   ├── domain/                       # Tests de entidades
│   ├── application/                  # Tests de casos de uso
│   └── infrastructure/               # Tests de persistencia
├── .env.example
├── config.ru
├── Gemfile
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
- **entities/**: Entidades con reglas de negocio (Cliente)
- **repositories/**: Interfaces/contratos de repositorios
- Responsabilidad: Lógica de negocio pura, sin dependencias externas
- Dependencias: Ninguna (núcleo independiente)

#### 🔧 Capa de Infraestructura (app/infrastructure/)
- **persistence/**: Implementación de repositorios y modelos ActiveRecord
- Responsabilidad: Detalles técnicos (DB, APIs externas, etc.)
- Dependencias: → Domain Layer (implementa interfaces)

## Instalación y Ejecución

### Requisitos
- Ruby >= 2.7.0
- Bundler
- SQLite3

### Setup

```bash
# Instalar dependencias
bundle install

# Configurar variables de entorno
cp .env.example .env

# Iniciar servidor
bundle exec puma config.ru -p 4001
```

### Con Docker

```bash
docker-compose up clientes-service
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
PORT=4001
DATABASE_URL=sqlite3:db/clientes.sqlite3
AUDITORIA_SERVICE_URL=http://localhost:4003
RACK_ENV=development
```

## Base de Datos

### Tabla: clientes

| Campo          | Tipo         | Descripción                |
|----------------|--------------|----------------------------|
| id             | INTEGER      | Primary Key                |
| nombre         | VARCHAR(255) | Nombre o razón social      |
| identificacion | VARCHAR(50)  | NIT/Cédula (UNIQUE)        |
| correo         | VARCHAR(255) | Email de contacto          |
| direccion      | TEXT         | Dirección completa         |
| created_at     | TIMESTAMP    | Fecha de creación          |
| updated_at     | TIMESTAMP    | Última actualización       |

### Índices
- `identificacion`: UNIQUE constraint para garantizar unicidad

## Integración

### Servicio de Auditoría
Registra eventos de forma asíncrona (fire-and-forget):
- CREATE: Cuando se crea un cliente
- READ: Cuando se consulta un cliente
- LIST: Cuando se lista clientes

**URL**: http://localhost:4003/auditoria
**Timeout**: 2 segundos
**Comportamiento**: Si falla, solo registra warning sin afectar operación principal

### Servicio de Facturas
Este servicio es consumido por Facturas Service para:
- Validar existencia de cliente antes de crear factura
- Obtener información del cliente

## Clean Architecture

El servicio sigue los principios de Clean Architecture:

**Domain Layer** (Independiente de frameworks):
- Entidades con reglas de negocio
- Interfaces de repositorios

**Application Layer** (Casos de uso):
- Orquesta la lógica de aplicación
- Coordina entre dominio e infraestructura

**Infrastructure Layer** (Adaptadores):
- Implementación de repositorios con ActiveRecord
- Comunicación con servicios externos

**Presentation Layer** (Controllers):
- API REST con Sinatra
- Validación de entrada HTTP
