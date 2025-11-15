# 📋 Instrucciones para Evaluadores - FactuMarket

Sistema de microservicios de facturación electrónica construido con Ruby, Clean Architecture y Docker.

---

## 🚀 Inicio Rápido (2 minutos)

### Requisitos Previos
- Docker Desktop instalado y corriendo
- Git (para clonar el repositorio)

### Pasos para Ejecutar

```bash
# 1. Clonar el repositorio
git clone <repository-url>
cd RubyDoubleV

# 2. Crear archivo de variables de entorno
cp .env.example .env

# 3. Levantar todos los servicios con Docker Compose
docker-compose up --build

# 4. ¡Listo! Los servicios estarán disponibles en:
# - Clientes:  http://localhost:4001/docs
# - Facturas:  http://localhost:4002/docs
# - Auditoría: http://localhost:4003/docs
```

---

## 🧪 Probar la Funcionalidad

### Opción 1: Swagger UI (Recomendado - Interfaz Visual)

1. **Abrir Swagger UI:**
   - Clientes: http://localhost:4001/docs
   - Facturas: http://localhost:4002/docs
   - Auditoría: http://localhost:4003/docs

2. **Autenticarse:**
   - Click en el botón **"Authorize" 🔓** (esquina superior derecha)
   - Pegar el siguiente token JWT:
     ```
     eyJhbGciOiJIUzI1NiJ9.eyJzZXJ2aWNlX25hbWUiOiJzd2FnZ2VyLXRlc3QiLCJpYXQiOjE3NjMxODE5MDEsImV4cCI6MTc2MzE4OTEwMX0.DCc9ROZELkT7EoCOGpm44jih5ZiPYxbtFy6AFRZJnWM
     ```
   - Click "Authorize"

3. **Probar los endpoints:**
   - Crear un cliente desde `/clientes` (POST)
   - Crear una factura desde `/facturas` (POST) usando el ID del cliente
   - Ver eventos en `/auditoria` (GET)

### Opción 2: Script Automatizado

Ejecutar el script de prueba completo:

```bash
bash test_local_complete.sh
```

Este script:
- ✅ Verifica health checks de los 3 servicios
- ✅ Crea un cliente
- ✅ Crea una factura (validando el cliente)
- ✅ Consulta eventos de auditoría
- ✅ Muestra toda la comunicación entre microservicios

### Opción 3: cURL Manual

```bash
# Token JWT
TOKEN="eyJhbGciOiJIUzI1NiJ9.eyJzZXJ2aWNlX25hbWUiOiJzd2FnZ2VyLXRlc3QiLCJpYXQiOjE3NjMxODE5MDEsImV4cCI6MTc2MzE4OTEwMX0.DCc9ROZELkT7EoCOGpm44jih5ZiPYxbtFy6AFRZJnWM"

# 1. Crear un cliente
curl -X POST http://localhost:4001/clientes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "nombre": "Empresa Test",
    "identificacion": "123456789",
    "correo": "test@empresa.com",
    "direccion": "Calle 123"
  }'

# 2. Crear una factura (usa el ID del cliente anterior)
curl -X POST http://localhost:4002/facturas \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "cliente_id": 1,
    "fecha_emision": "2025-11-15",
    "monto": 1000000,
    "items": [
      {
        "descripcion": "Servicio de consultoría",
        "cantidad": 1,
        "precio_unitario": 1000000,
        "subtotal": 1000000
      }
    ]
  }'

# 3. Ver eventos de auditoría
curl http://localhost:4003/auditoria?limit=10 \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🏗️ Arquitectura del Sistema

### Microservicios

| Servicio | Puerto | Base de Datos | Arquitectura |
|----------|--------|---------------|--------------|
| **Clientes** | 4001 | SQLite3 | Clean Architecture |
| **Facturas** | 4002 | SQLite3 | Clean Architecture |
| **Auditoría** | 4003 | MongoDB | MVC |

### Comunicación Entre Servicios

```
┌─────────────┐      valida      ┌─────────────┐
│  Facturas   │ ───────────────> │  Clientes   │
│  Service    │   (síncrona)     │  Service    │
└─────────────┘                  └─────────────┘
      │                                 │
      │ eventos                   eventos │
      │ (async)                   (async) │
      ▼                                 ▼
┌─────────────────────────────────────────────┐
│          Auditoría Service                   │
│          (MongoDB)                           │
└─────────────────────────────────────────────┘
```

**Flujo de Creación de Factura:**
1. Request POST a Facturas Service
2. Facturas valida que el cliente existe consultando a Clientes Service (HTTP síncrono)
3. Si existe, crea la factura
4. Ambos servicios envían eventos a Auditoría (HTTP asíncrono)

---

## 📊 Bases de Datos

### SQLite (Clientes y Facturas)

**Nota:** Se utilizó SQLite en lugar de Oracle por:
- ✅ Facilidad de configuración y deployment
- ✅ Portabilidad total (archivo único)
- ✅ Ideal para demostración
- ✅ Cumple con ACID
- ⚠️ Inconvenientes técnicos con Oracle-Ruby en desarrollo

**Arquitectura:** Patrón Repository permite migrar fácilmente a Oracle/PostgreSQL.

**Ver datos:**
```bash
# Clientes
docker exec factumarket-clientes sqlite3 /app/db/clientes.sqlite3 "SELECT * FROM clientes;"

# Facturas
docker exec factumarket-facturas sqlite3 /app/db/facturas.sqlite3 "SELECT * FROM facturas;"
```

### MongoDB (Auditoría)

**Ver eventos:**
```bash
docker exec factumarket-mongodb mongosh -u admin -p factumarket_secure_2025 \
  --authenticationDatabase admin \
  --eval "db.getSiblingDB('auditoria_db').audit_events.find().limit(10)"
```

---

## 🔐 Autenticación JWT

Todos los endpoints (excepto `/health` y `/docs`) requieren JWT.

**Token de prueba incluido:**
```
eyJhbGciOiJIUzI1NiJ9.eyJzZXJ2aWNlX25hbWUiOiJzd2FnZ2VyLXRlc3QiLCJpYXQiOjE3NjMxODE5MDEsImV4cCI6MTc2MzE4OTEwMX0.DCc9ROZELkT7EoCOGpm44jih5ZiPYxbtFy6AFRZJnWM
```

**Generar nuevo token (opcional):**
```ruby
require 'jwt'
payload = { service_name: 'test', iat: Time.now.to_i, exp: Time.now.to_i + 3600 }
secret = '160b6ba480729089b07d54020388926db99330c793e77fb6530262f973121077'
token = JWT.encode(payload, secret, 'HS256')
puts token
```

---

## 🧹 Detener y Limpiar

```bash
# Detener servicios
docker-compose down

# Limpiar todo (incluyendo volúmenes y bases de datos)
docker-compose down -v

# Ver logs de un servicio específico
docker logs factumarket-clientes
docker logs factumarket-facturas
docker logs factumarket-auditoria
```

---

## 📁 Archivos Necesarios

Para que todo funcione correctamente, necesitas:

### ✅ **Archivos incluidos en el repositorio:**
- `docker-compose.yml` - Configuración de servicios
- `.env.example` - Template de variables de entorno
- `README.md` - Documentación general
- `test_local_complete.sh` - Script de prueba automatizado
- Todo el código fuente de los 3 microservicios

### ⚠️ **Archivo que debes crear:**
- `.env` - Variables de entorno (copiar desde `.env.example`)

**Comando:**
```bash
cp .env.example .env
```

El archivo `.env.example` ya viene configurado con valores por defecto que funcionan con Docker Compose.

---

## 🌐 Versión en Producción

El sistema también está desplegado en producción:

- **Clientes:** https://clientes-ruby-double-v.ondeploy.space/docs
- **Facturas:** https://factura-ruby-double-v.ondeploy.space/docs
- **Auditoría:** https://auditoria-ruby-double-v.ondeploy.space/docs

Mismo token JWT funciona en producción.

---

## 🐛 Troubleshooting

### Puerto ya en uso
```bash
# Cambiar puertos en .env
CLIENTES_PORT=4011
FACTURAS_PORT=4012
AUDITORIA_PORT=4013

# Reiniciar
docker-compose down
docker-compose up
```

### Servicios no se comunican
```bash
# Verificar que las URLs usan nombres de contenedores
grep CLIENTES_SERVICE_URL .env
# Debe mostrar: CLIENTES_SERVICE_URL=http://factumarket-clientes:4001
```

### MongoDB no conecta
```bash
# Verificar que MongoDB esté corriendo
docker ps | grep mongodb

# Ver logs
docker logs factumarket-mongodb
```

### JWT inválido
El token de prueba expira después de 2 horas. Generar uno nuevo con el script de Ruby arriba.

---

## 📝 Características Principales

- ✅ **Clean Architecture** en Clientes y Facturas
- ✅ **Patrón MVC** en Auditoría
- ✅ **API REST** documentada con OpenAPI 3.1
- ✅ **Swagger UI** interactivo
- ✅ **JWT** para autenticación
- ✅ **Docker Compose** para orquestación
- ✅ **Testing** con RSpec
- ✅ **Bases de datos:** SQLite + MongoDB
- ✅ **Comunicación síncrona y asíncrona** entre servicios

---

## 📧 Soporte

Si tienes algún problema:
1. Verifica que Docker Desktop esté corriendo
2. Revisa los logs: `docker-compose logs`
3. Asegúrate de que `.env` existe y está configurado correctamente

---

**¡Gracias por evaluar este proyecto!** 🚀
