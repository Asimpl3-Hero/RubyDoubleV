# FactuMarket - Sistema de Facturación Electrónica

![Ruby](https://img.shields.io/badge/Ruby-3.2+-CC342D?style=for-the-badge&logo=ruby&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Swagger](https://img.shields.io/badge/Swagger-85EA2D?style=for-the-badge&logo=swagger&logoColor=black)
![MongoDB](https://img.shields.io/badge/MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white)
![Oracle](https://img.shields.io/badge/Oracle-F80000?style=for-the-badge&logo=oracle&logoColor=white)

Sistema de microservicios para facturación electrónica construido con Ruby, aplicando **Clean Architecture**, **MVC** y utilizando bases de datos **Oracle/SQLite** (transaccional) y **MongoDB** (auditoría).

## Índice

- [Características](#características)
- [Arquitectura](#arquitectura)
- [Requisitos Previos](#requisitos-previos)
- [Instalación](#instalación)
- [Ejecución](#ejecución)
- [Testing](#testing)
- [Documentación de APIs](#documentación-de-apis)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Tecnologías Utilizadas](#tecnologías-utilizadas)

## Características

✅ **Arquitectura de Microservicios** independientes y escalables <br>
✅ **Clean Architecture** aplicada en servicios de Clientes y Facturas <br>
✅ **Patrón MVC** en capa de presentación (Controllers, Models, Views) <br>
✅ **Base de datos Oracle/SQLite** para datos transaccionales <br>
✅ **MongoDB** para registro de eventos de auditoría <br>
✅ **API REST** con respuestas JSON <br>
✅ **Documentación interactiva** con Swagger UI (OpenAPI 3.0) <br>
✅ **Pruebas unitarias** para lógica de dominio <br>
✅ **Docker** y **Docker Compose** para deployment <br>
✅ **Comunicación entre servicios** vía HTTP REST <br>

## Arquitectura

El sistema está compuesto por 3 microservicios:

### 1. **Servicio de Clientes** (Puerto 4001)

- Gestión de clientes (CRUD)
- Persistencia en Oracle/SQLite
- Clean Architecture + MVC
- Registro de eventos en Auditoría

### 2. **Servicio de Facturas** (Puerto 4002)

- Creación y gestión de facturas electrónicas
- Validación de clientes (integración con servicio de Clientes)
- Persistencia en Oracle/SQLite
- Clean Architecture + MVC
- Registro de eventos en Auditoría

### 3. **Servicio de Auditoría** (Puerto 4003)

- Registro de todos los eventos del sistema
- Persistencia en MongoDB (NoSQL)
- Consulta de eventos por entidad

Ver [documentación detallada de arquitectura](docs/ARQUITECTURA.md).

## Requisitos Previos

### Opción 1: Con Docker (Recomendado)

- Docker >= 20.x
- Docker Compose >= 2.x

### Opción 2: Sin Docker (Desarrollo local)

- Ruby >= 2.7.0 (recomendado 3.2+)
- Bundler >= 2.0
- SQLite3
- MongoDB >= 5.0
- Git

## Instalación

### Con Docker

```bash
# Clonar el repositorio
git clone <repository-url>
cd RubyDoubleV

# Construir y levantar servicios
docker-compose up --build
```

Los servicios estarán disponibles en:

- Clientes Service: http://localhost:4001
- Facturas Service: http://localhost:4002
- Auditoría Service: http://localhost:4003
- MongoDB: localhost:27017

### Sin Docker (Desarrollo local)

```bash
# Clonar el repositorio
git clone <repository-url>
cd RubyDoubleV

# Ejecutar script de setup
chmod +x scripts/setup.sh
./scripts/setup.sh
```

O manualmente:

```bash
# Servicio de Auditoría (debe iniciarse primero)
cd auditoria-service
cp .env.example .env
bundle install
bundle exec puma config.ru -p 4003 &

# Servicio de Clientes
cd ../clientes-service
cp .env.example .env
bundle install
bundle exec rake db:migrate
bundle exec puma config.ru -p 4001 &

# Servicio de Facturas
cd ../facturas-service
cp .env.example .env
bundle install
bundle exec rake db:migrate
bundle exec puma config.ru -p 4002 &
```

## Ejecución

### Iniciar todos los servicios con Docker

```bash
docker-compose up
```

### Detener servicios

```bash
docker-compose down
```

### Ver logs

```bash
# Todos los servicios
docker-compose logs -f

# Un servicio específico
docker-compose logs -f clientes-service
```

### Health Checks

```bash
# Verificar que todos los servicios estén corriendo
curl http://localhost:4001/health  # Clientes
curl http://localhost:4002/health  # Facturas
curl http://localhost:4003/health  # Auditoría
```

### Documentación Interactiva con Swagger UI

Cada servicio incluye documentación interactiva con Swagger UI basada en especificaciones OpenAPI 3.0:

```bash
# Swagger UI (Interfaz visual interactiva)
http://localhost:4001/docs  # Clientes Service
http://localhost:4002/docs  # Facturas Service
http://localhost:4003/docs  # Auditoría Service

# Especificaciones OpenAPI (YAML)
http://localhost:4001/api-docs  # Clientes OpenAPI Spec
http://localhost:4002/api-docs  # Facturas OpenAPI Spec
http://localhost:4003/api-docs  # Auditoría OpenAPI Spec
```

**Características de Swagger UI:**

- Documentación completa de todos los endpoints
- Ejemplos de request/response
- Pruebas interactivas (Try it out)
- Esquemas de datos con validaciones
- Filtrado por tags (clientes, facturas, auditoría, health)

## Documentación de APIs

### Servicio de Clientes (Puerto 4001)

#### POST /clientes - Crear cliente

```bash
curl -X POST http://localhost:4001/clientes \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Empresa ABC S.A.",
    "identificacion": "900123456",
    "correo": "contacto@empresaabc.com",
    "direccion": "Calle 123 #45-67, Bogotá"
  }'
```

**Respuesta:**

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

#### GET /clientes/:id - Consultar cliente

```bash
curl http://localhost:4001/clientes/1
```

#### GET /clientes - Listar todos los clientes

```bash
curl http://localhost:4001/clientes
```

---

### Servicio de Facturas (Puerto 4002)

#### POST /facturas - Crear factura

```bash
curl -X POST http://localhost:4002/facturas \
  -H "Content-Type: application/json" \
  -d '{
    "cliente_id": 1,
    "fecha_emision": "2025-01-13",
    "monto": 1500000,
    "items": [
      {
        "descripcion": "Producto A",
        "cantidad": 2,
        "precio_unitario": 500000,
        "subtotal": 1000000
      },
      {
        "descripcion": "Producto B",
        "cantidad": 1,
        "precio_unitario": 500000,
        "subtotal": 500000
      }
    ]
  }'
```

**Respuesta:**

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

#### GET /facturas/:id - Consultar factura

```bash
curl http://localhost:4002/facturas/1
```

#### GET /facturas - Listar facturas

```bash
# Todas las facturas
curl http://localhost:4002/facturas

# Por rango de fechas
curl "http://localhost:4002/facturas?fechaInicio=2025-01-01&fechaFin=2025-01-31"
```

---

### Servicio de Auditoría (Puerto 4003)

#### GET /auditoria/:factura_id - Eventos de una factura

```bash
curl http://localhost:4003/auditoria/1
```

#### GET /auditoria/cliente/:cliente_id - Eventos de un cliente

```bash
curl http://localhost:4003/auditoria/cliente/1
```

#### GET /auditoria - Todos los eventos

```bash
# Últimos 100 eventos
curl http://localhost:4003/auditoria

# Filtrar por acción
curl "http://localhost:4003/auditoria?action=CREATE&limit=50"

# Filtrar por estado
curl "http://localhost:4003/auditoria?status=ERROR&limit=20"
```

---

## Estructura del Proyecto

```
RubyDoubleV/
├── clientes-service/              # Microservicio de Clientes
│   ├── app/
│   │   ├── controllers/           # Controllers (MVC)
│   │   ├── models/                # Models ActiveRecord (MVC)
│   │   ├── domain/                # Clean Architecture
│   │   │   ├── entities/          # Entidades de dominio
│   │   │   └── repositories/      # Interfaces de repositorios
│   │   ├── application/           # Clean Architecture
│   │   │   └── use_cases/         # Casos de uso
│   │   └── infrastructure/        # Clean Architecture
│   │       └── persistence/       # Implementación de repositorios
│   ├── config/                    # Configuración
│   ├── db/                        # Migraciones y BD
│   ├── spec/                      # Pruebas unitarias
│   ├── Gemfile
│   ├── config.ru
│   └── Dockerfile
│
├── facturas-service/              # Microservicio de Facturas
│   └── (estructura similar a clientes-service)
│
├── auditoria-service/             # Microservicio de Auditoría
│   ├── app/
│   │   ├── controllers/           # Controllers (MVC)
│   │   ├── models/                # Models (MVC)
│   │   └── infrastructure/        # Persistencia MongoDB
│   ├── config/
│   ├── Gemfile
│   ├── config.ru
│   └── Dockerfile
│
├── docs/                          # Documentación
│   └── ARQUITECTURA.md
│
├── db/                            # Scripts de BD
│   ├── init_oracle.sql
│   └── init_mongodb.js
│
├── scripts/                       # Scripts de utilidad
│   ├── setup.sh
│   └── test.sh
│
├── docker-compose.yml
└── README.md
```

## Tecnologías Utilizadas

- **Ruby 3.2+**: Lenguaje de programación
- **Sinatra**: Framework web minimalista
- **Puma**: Servidor de aplicaciones
- **ActiveRecord**: ORM para bases de datos relacionales
- **SQLite3**: Base de datos para desarrollo (reemplazable por Oracle)
- **MongoDB**: Base de datos NoSQL para auditoría
- **HTTParty**: Cliente HTTP para comunicación entre servicios
- **RSpec**: Testing framework
- **Dry-Validation**: Validaciones de datos
- **OpenAPI 3.0 & Swagger UI**: Documentación interactiva de APIs
- **Docker & Docker Compose**: Containerización

## Aplicación de Principios

### Clean Architecture

Los servicios de **Clientes** y **Facturas** implementan Clean Architecture con 4 capas:

1. **Domain Layer** (`app/domain/`): Lógica de negocio pura

   - Entidades con validaciones
   - Interfaces de repositorios
   - Sin dependencias externas

2. **Application Layer** (`app/application/`): Casos de uso

   - Orquestación de lógica de negocio
   - Coordinación entre entidades y repositorios

3. **Infrastructure Layer** (`app/infrastructure/`): Adaptadores

   - Implementación de repositorios con ActiveRecord
   - Conexión con bases de datos

4. **Presentation Layer** (`app/controllers/`): API REST
   - Controllers con patrón MVC
   - Manejo de HTTP requests/responses

### MVC (Model-View-Controller)

- **Model**: Modelos ActiveRecord (`app/models/`)
- **View**: Respuestas JSON (API REST)
- **Controller**: Controllers Sinatra (`app/controllers/`)

### Microservicios

- Cada servicio es independiente
- Base de datos por servicio
- Comunicación vía API REST
- Despliegue autónomo

## Configuración para Oracle (Producción)

Para usar Oracle en lugar de SQLite, actualizar `config/database.yml`:

```yaml
production:
  adapter: oracle_enhanced
  database: //localhost:1521/XEPDB1
  username: <%= ENV['ORACLE_USER'] %>
  password: <%= ENV['ORACLE_PASSWORD'] %>
```

Y ejecutar el script de inicialización:

```bash
sqlplus factumarket_user/password@localhost:1521/XEPDB1 < db/init_oracle.sql
```

## Contribución

Este proyecto fue desarrollado como prueba técnica para el equipo de Double V Partners.

## Autor

Desarrollado por Justin Hernandez Tobinson.
