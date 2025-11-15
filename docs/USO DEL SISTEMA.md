# 📘 Guía de Uso - FactuMarket

> Guía completa para instalar, configurar y usar el sistema de facturación electrónica.

---

## 📋 Tabla de Contenidos

- [Instalación y Configuración](#-instalación-y-configuración)
- [Acceso a los Servicios](#-acceso-a-los-servicios)
- [Flujo Completo: Crear Cliente y Factura](#-flujo-completo-crear-cliente-y-factura)
- [Ejemplos de API por Servicio](#-ejemplos-de-api-por-servicio)
- [Casos de Error Comunes](#-casos-de-error-comunes)
- [Testing Automatizado](#-testing-automatizado)

---

## 🚀 Instalación y Configuración

### Opción 1: Docker Compose (Recomendado)

**Requisitos:**

- Docker >= 20.x
- Docker Compose >= 2.x

**Pasos de instalación:**

```bash
# 1. Clonar el repositorio
git clone <repository-url>
cd RubyDoubleV

# 2. Configurar variables de entorno
cp .env.example .env

# 3. Iniciar todos los servicios
docker-compose up --build
```

**¿Qué hace Docker Compose?**

```mermaid
graph LR
    DC[docker-compose up] --> M[MongoDB Container]
    DC --> A[Auditoría Service]
    DC --> C[Clientes Service]
    DC --> F[Facturas Service]

    A --> M
    C --> SQL1[(SQLite DB)]
    F --> SQL2[(SQLite DB)]
```

Docker Compose orquesta:

- ✅ **4 contenedores**: MongoDB + 3 microservicios
- ✅ **Red interna**: `factumarket-network` para comunicación
- ✅ **Volúmenes**: Persistencia de MongoDB
- ✅ **Puertos expuestos**: 4001, 4002, 4003, 27017

### Opción 2: Desarrollo Local (Sin Docker)

**Requisitos:**

- Ruby >= 3.2
- MongoDB >= 5.0
- SQLite3

```bash
# Terminal 1: MongoDB
mongod --dbpath ./data/db

# Terminal 2: Auditoría Service
cd auditoria-service
cp .env.example .env
bundle install
bundle exec puma config.ru -p 4003

# Terminal 3: Clientes Service
cd clientes-service
cp .env.example .env
bundle install
bundle exec puma config.ru -p 4001

# Terminal 4: Facturas Service
cd facturas-service
cp .env.example .env
bundle install
bundle exec puma config.ru -p 4002
```

### 🐳 Comandos Docker Útiles

```bash
# Iniciar todos los servicios
docker-compose up

# Iniciar en background (detached)
docker-compose up -d

# Rebuild forzado de imágenes
docker-compose up --build

# Ver logs en tiempo real
docker-compose logs -f

# Logs de un servicio específico
docker-compose logs -f clientes-service

# Detener servicios
docker-compose down

# Detener y eliminar volúmenes
docker-compose down -v

# Ver estado de contenedores
docker-compose ps
```

### 📊 Conexión a MongoDB

**Local (Desarrollo):**
```
mongodb://admin:factumarket_secure_2025@localhost:27017/?authSource=admin
```

**Producción (Servidor):**
```
mongodb://admin:factumarket_secure_2025@165.154.245.7:27017/?authSource=admin
```

| Parámetro | Valor |
|-----------|-------|
| **Usuario** | `admin` |
| **Password** | `factumarket_secure_2025` |
| **Base de datos** | `auditoria_db` |
| **Auth Source** | `admin` |

**Herramientas recomendadas:**
- [MongoDB Compass](https://www.mongodb.com/products/compass) - GUI oficial
- [Studio 3T](https://studio3t.com/) - Cliente avanzado

**Colecciones disponibles:**
- `audit_events` - Registros de auditoría del sistema

---

## 🌐 Acceso a los Servicios

### Localhost (Desarrollo)

| Servicio      | URL Base              | Swagger UI                          | Health Check                            |
| ------------- | --------------------- | ----------------------------------- | --------------------------------------- |
| **Clientes**  | http://localhost:4001 | [/docs](http://localhost:4001/docs) | [/health](http://localhost:4001/health) |
| **Facturas**  | http://localhost:4002 | [/docs](http://localhost:4002/docs) | [/health](http://localhost:4002/health) |
| **Auditoría** | http://localhost:4003 | [/docs](http://localhost:4003/docs) | [/health](http://localhost:4003/health) |
| **MongoDB**   | localhost:27017       | -                                   | -                                       |

### Producción (Dokploy)

| Servicio      | URL                                            | Swagger UI                                                   | Health Check                                                    |
| ------------- | ---------------------------------------------- | ------------------------------------------------------------ | --------------------------------------------------------------- |
| **Clientes**  | https://clientes-ruby-double-v.ondeploy.space  | [/docs](https://clientes-ruby-double-v.ondeploy.space/docs)  | [/health](https://clientes-ruby-double-v.ondeploy.space/health) |
| **Facturas**  | https://factura-ruby-double-v.ondeploy.space   | [/docs](https://factura-ruby-double-v.ondeploy.space/docs)   |
| **Auditoría** | https://auditoria-ruby-double-v.ondeploy.space | [/docs](https://auditoria-ruby-double-v.ondeploy.space/docs) |

### 🏥 Health Checks

Verificar que los servicios estén corriendo correctamente:

**Desarrollo (localhost):**
```bash
curl http://localhost:4001/health
curl http://localhost:4002/health
curl http://localhost:4003/health
```

**Producción:**
```bash
curl https://clientes-ruby-double-v.ondeploy.space/health
curl https://factura-ruby-double-v.ondeploy.space/health
curl https://auditoria-ruby-double-v.ondeploy.space/health
```

**Respuesta esperada:**
```json
{
  "success": true,
  "service": "clientes-service",
  "status": "running",
  "timestamp": "2025-01-13T15:30:00Z"
}
```

### 📖 Documentación Swagger

Cada servicio incluye documentación interactiva Swagger UI:

| Servicio | Swagger UI | OpenAPI Spec |
|----------|-----------|--------------|
| **Clientes** | [/docs](https://clientes-ruby-double-v.ondeploy.space/docs) | [/api-docs](https://clientes-ruby-double-v.ondeploy.space/api-docs) |
| **Facturas** | [/docs](https://factura-ruby-double-v.ondeploy.space/docs) | [/api-docs](https://factura-ruby-double-v.ondeploy.space/api-docs) |
| **Auditoría** | [/docs](https://auditoria-ruby-double-v.ondeploy.space/docs) | [/api-docs](https://auditoria-ruby-double-v.ondeploy.space/api-docs) |

#### 📸 Vistas Previas de Swagger UI

**Servicio de Clientes**

![Swagger UI - Clientes Service](../public/images/SwaggerImageClients.png)

**Servicio de Facturas**

![Swagger UI - Facturas Service](../public/images/SwaggerImageFacture.png)

**Servicio de Auditoría**

![Swagger UI - Auditoría Service](../public/images/SwaggerImageAuditory.png)

---

## 🔄 Flujo Completo: Crear Cliente y Factura

### Paso 1️⃣: Crear un Cliente

```bash
curl -X POST http://localhost:4001/clientes \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Tienda El Ahorro S.A.S.",
    "identificacion": "900555123",
    "correo": "contacto@elahorro.com",
    "direccion": "Carrera 7 #12-34, Bogotá"
  }'
```

<details>
<summary>📄 Ver respuesta exitosa</summary>

```json
{
  "success": true,
  "message": "Cliente creado exitosamente",
  "data": {
    "id": 1,
    "nombre": "Tienda El Ahorro S.A.S.",
    "identificacion": "900555123",
    "correo": "contacto@elahorro.com",
    "direccion": "Carrera 7 #12-34, Bogotá",
    "created_at": "2025-01-13T15:30:00.000Z"
  }
}
```

</details>

### Paso 2️⃣: Crear una Factura

```bash
curl -X POST http://localhost:4002/facturas \
  -H "Content-Type: application/json" \
  -d '{
    "cliente_id": 1,
    "fecha_emision": "2025-01-13",
    "monto": 2500000,
    "items": [
      {
        "descripcion": "Laptop Dell",
        "cantidad": 1,
        "precio_unitario": 1800000,
        "subtotal": 1800000
      },
      {
        "descripcion": "Mouse",
        "cantidad": 2,
        "precio_unitario": 50000,
        "subtotal": 100000
      }
    ]
  }'
```

<details>
<summary>📄 Ver respuesta exitosa</summary>

```json
{
  "success": true,
  "message": "Factura creada exitosamente",
  "data": {
    "id": 1,
    "cliente_id": 1,
    "numero_factura": "F-20250113-A1B2C3D4",
    "fecha_emision": "2025-01-13",
    "monto": 2500000.0,
    "estado": "EMITIDA"
  }
}
```

</details>

### Paso 3️⃣: Consultar Auditoría

```bash
# Eventos del cliente
curl http://localhost:4003/auditoria/cliente/1

# Eventos de la factura
curl http://localhost:4003/auditoria/1

# Últimos eventos
curl http://localhost:4003/auditoria?limit=10
```

---

## 📚 Ejemplos de API por Servicio

### 🟢 Clientes Service

| Operación | Método | Endpoint        | Descripción                |
| --------- | ------ | --------------- | -------------------------- |
| Crear     | POST   | `/clientes`     | Crea un nuevo cliente      |
| Obtener   | GET    | `/clientes/:id` | Consulta un cliente por ID |
| Listar    | GET    | `/clientes`     | Lista todos los clientes   |

**Ejemplo: Listar clientes**

```bash
curl http://localhost:4001/clientes
```

### 🔵 Facturas Service

| Operación | Método | Endpoint                                 | Descripción                 |
| --------- | ------ | ---------------------------------------- | --------------------------- |
| Crear     | POST   | `/facturas`                              | Crea una nueva factura      |
| Obtener   | GET    | `/facturas/:id`                          | Consulta una factura por ID |
| Listar    | GET    | `/facturas`                              | Lista todas las facturas    |
| Filtrar   | GET    | `/facturas?fechaInicio=...&fechaFin=...` | Filtra por rango de fechas  |

**Ejemplo: Filtrar facturas por fecha**

```bash
curl "http://localhost:4002/facturas?fechaInicio=2025-01-01&fechaFin=2025-01-31"
```

### 🟡 Auditoría Service

| Operación   | Método | Endpoint                                  | Descripción                  |
| ----------- | ------ | ----------------------------------------- | ---------------------------- |
| Por Factura | GET    | `/auditoria/:factura_id`                  | Eventos de una factura       |
| Por Cliente | GET    | `/auditoria/cliente/:cliente_id`          | Eventos de un cliente        |
| Todos       | GET    | `/auditoria`                              | Todos los eventos (paginado) |
| Filtrar     | GET    | `/auditoria?action=CREATE&status=SUCCESS` | Filtra por acción/estado     |

**Ejemplo: Solo errores**

```bash
curl "http://localhost:4003/auditoria?status=ERROR&limit=20"
```

---

## ⚠️ Casos de Error Comunes

| Escenario              | HTTP Status | Error                                    | Solución                                          |
| ---------------------- | ----------- | ---------------------------------------- | ------------------------------------------------- |
| Cliente inexistente    | 422         | `Cliente con ID X no existe`             | Verificar ID del cliente antes de crear factura   |
| Monto negativo         | 400         | `Monto debe ser mayor a 0`               | Validar monto > 0                                 |
| Cliente duplicado      | 400         | `Cliente con identificación X ya existe` | Usar identificación única                         |
| Servicio no disponible | 503         | `timeout/connection unavailable`         | Verificar que todos los servicios estén corriendo |

**Ejemplo de error:**

```bash
curl -X POST http://localhost:4002/facturas -H "Content-Type: application/json" \
  -d '{"cliente_id": 999, "fecha_emision": "2025-01-13", "monto": 1000000}'

# Respuesta:
# {"success": false, "error": "Cliente con ID 999 no existe o no está disponible"}
```

---

## 🧪 Testing Automatizado

### Opción 1: Tests con RSpec

**Ejecutar tests por servicio:**

```bash
# Clientes Service
cd clientes-service
bundle exec rspec

# Facturas Service
cd facturas-service
bundle exec rspec

# Auditoría Service
cd auditoria-service
bundle exec rspec
```

**Tests específicos:**

```bash
# Solo tests de dominio
bundle exec rspec spec/domain/

# Solo tests de casos de uso
bundle exec rspec spec/application/

# Solo tests de integración
bundle exec rspec spec/interfaces/

# Test específico con línea
bundle exec rspec spec/domain/entities/cliente_spec.rb:15
```

**Con formato detallado:**
```bash
bundle exec rspec --format documentation
```

Ver [TESTING.md](TESTING.md) para la suite completa de pruebas y cobertura.

### Opción 2: Colección Postman

1. Descargar [Postman](https://www.postman.com/downloads/)
2. Importar colección desde: `postman/FactuMarket.postman_collection.json` (si existe)
3. O crear nueva colección con los endpoints documentados en este archivo

### Opción 3: Swagger UI Interactivo

La forma más fácil de probar la API es usando Swagger UI:

1. Abrir http://localhost:4001/docs (Clientes)
2. Abrir http://localhost:4002/docs (Facturas)
3. Abrir http://localhost:4003/docs (Auditoría)
4. Usar el botón "Try it out" en cada endpoint

---

## 📌 Notas Importantes

- ✅ Todos los servicios deben estar corriendo antes de ejecutar pruebas
- ✅ Los eventos de auditoría se registran de forma **asíncrona** (no bloquean operaciones)
- ✅ Si MongoDB no está disponible, los servicios seguirán funcionando pero **sin auditoría**
- ✅ Usar Swagger UI (`/docs`) para probar endpoints de forma interactiva
