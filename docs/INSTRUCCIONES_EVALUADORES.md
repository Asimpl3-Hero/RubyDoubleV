# 📋 Instrucciones para Evaluadores - FactuMarket

> 🚀 Sistema de microservicios de facturación electrónica con Ruby, Clean Architecture y Docker.

---

## ⚡ Inicio Rápido (3 minutos)

**Requisitos previos:**
- ✅ Docker Desktop instalado y corriendo
- ✅ Git

```bash
# 1. Clonar y configurar
git clone <repository-url>
cd RubyDoubleV
cp .env.example .env

# 2. Levantar servicios
docker-compose up --build

# 3. Acceder a las interfaces Swagger
# - 🟢 Clientes:  http://localhost:4001/docs
# - 🔵 Facturas:  http://localhost:4002/docs
# - 🟡 Auditoría: http://localhost:4003/docs
```

---

## ✅ Verificar que todo esté corriendo

```bash
# Health checks
curl http://localhost:4001/health  # Clientes
curl http://localhost:4002/health  # Facturas
curl http://localhost:4003/health  # Auditoría

# Ver logs si hay problemas
docker-compose logs
```

---

## 🧪 Probar el Sistema

### 🎯 Opción 1: Swagger UI (Recomendado)

1. **Abrir Swagger UI:** http://localhost:4001/docs (o cualquier servicio)
2. **Autenticarse:** Click en 🔓 "Authorize" (esquina superior derecha)
3. **Pegar token:**
   ```
   eyJhbGciOiJIUzI1NiJ9.eyJzZXJ2aWNlX25hbWUiOiJzd2FnZ2VyLXRlc3QiLCJpYXQiOjE3NjMxODE5MDEsImV4cCI6MTc2MzE4OTEwMX0.DCc9ROZELkT7EoCOGpm44jih5ZiPYxbtFy6AFRZJnWM
   ```
4. **Probar endpoints:**
   - 🟢 POST `/clientes` - Crear cliente
   - 🔵 POST `/facturas` - Crear factura (usar ID del cliente)
   - 🟡 GET `/auditoria` - Ver eventos

### 💻 Opción 2: cURL

```bash
TOKEN="eyJhbGciOiJIUzI1NiJ9.eyJzZXJ2aWNlX25hbWUiOiJzd2FnZ2VyLXRlc3QiLCJpYXQiOjE3NjMxODE5MDEsImV4cCI6MTc2MzE4OTEwMX0.DCc9ROZELkT7EoCOGpm44jih5ZiPYxbtFy6AFRZJnWM"

# Crear cliente
curl -X POST http://localhost:4001/clientes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"nombre":"Empresa Test","identificacion":"123456789","correo":"test@empresa.com","direccion":"Calle 123"}'

# Crear factura (usar ID del cliente anterior)
curl -X POST http://localhost:4002/facturas \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"cliente_id":1,"fecha_emision":"2025-11-15","monto":1000000,"items":[{"descripcion":"Consultoría","cantidad":1,"precio_unitario":1000000,"subtotal":1000000}]}'

# Ver auditoría
curl http://localhost:4003/auditoria?limit=10 -H "Authorization: Bearer $TOKEN"
```

---

## 🧬 Ejecutar Tests

```bash
# Tests del servicio de Clientes
docker exec factumarket-clientes bundle exec rspec

# Tests del servicio de Facturas
docker exec factumarket-facturas bundle exec rspec

# Tests del servicio de Auditoría
docker exec factumarket-auditoria bundle exec rspec
```

---

## 🏗️ Arquitectura

| Servicio | Puerto | Base de Datos | Arquitectura |
|----------|--------|---------------|--------------|
| 🟢 Clientes | 4001 | SQLite3 | Clean Architecture |
| 🔵 Facturas | 4002 | SQLite3 | Clean Architecture |
| 🟡 Auditoría | 4003 | MongoDB | MVC |

**🔄 Comunicación entre servicios:**
- ⚡ Facturas → Clientes (HTTP síncrono): Valida existencia del cliente
- 📤 Facturas → Auditoría (HTTP asíncrono): Registra eventos
- 📤 Clientes → Auditoría (HTTP asíncrono): Registra eventos

---

## 🔍 Inspeccionar Datos

```bash
# SQLite - Clientes
docker exec factumarket-clientes sqlite3 /app/db/clientes.sqlite3 "SELECT * FROM clientes;"

# SQLite - Facturas
docker exec factumarket-facturas sqlite3 /app/db/facturas.sqlite3 "SELECT * FROM facturas;"

# MongoDB - Auditoría
docker exec factumarket-mongodb mongosh -u admin -p factumarket_secure_2025 \
  --authenticationDatabase admin \
  --eval "db.getSiblingDB('auditoria_db').audit_events.find().limit(10)"
```

> 💡 **Nota sobre SQLite:** Se usó en lugar de Oracle por portabilidad y facilidad de demo. El patrón Repository permite migrar fácilmente a Oracle/PostgreSQL.

---

## 🔐 Autenticación JWT

Todos los endpoints (excepto `/health` y `/docs`) requieren JWT en header: `Authorization: Bearer <token>`

**Token de prueba (válido por 2 horas):**
```
eyJhbGciOiJIUzI1NiJ9.eyJzZXJ2aWNlX25hbWUiOiJzd2FnZ2VyLXRlc3QiLCJpYXQiOjE3NjMxODE5MDEsImV4cCI6MTc2MzE4OTEwMX0.DCc9ROZELkT7EoCOGpm44jih5ZiPYxbtFy6AFRZJnWM
```

### 🔄 Refresco de JWT (Si el token expira)

El token de prueba tiene una duración de **2 horas**. Si expira, puedes generar uno nuevo:

#### 📍 Opción 1: Desde Docker (Recomendado)

```bash
docker exec factumarket-clientes ruby -r jwt -e "puts JWT.encode({ service_name: 'test', iat: Time.now.to_i, exp: Time.now.to_i + 7200 }, '160b6ba480729089b07d54020388926db99330c793e77fb6530262f973121077', 'HS256')"
```

#### 📍 Opción 2: Ruby local (si tienes Ruby instalado)

```bash
ruby -r jwt -e "puts JWT.encode({ service_name: 'test', iat: Time.now.to_i, exp: Time.now.to_i + 7200 }, '160b6ba480729089b07d54020388926db99330c793e77fb6530262f973121077', 'HS256')"
```

> ⚠️ **Importante:** Asegúrate de usar el mismo `JWT_SECRET_KEY` configurado en tu archivo `.env`

---

## 🛑 Detener Servicios

```bash
docker-compose down           # Detener
docker-compose down -v        # Detener y limpiar bases de datos
docker logs factumarket-clientes  # Ver logs
```

---

## 🌐 Producción

Sistema desplegado en la nube:

- 🟢 **Clientes:** https://clientes-ruby-double-v.ondeploy.space/docs
- 🔵 **Facturas:** https://factura-ruby-double-v.ondeploy.space/docs
- 🟡 **Auditoría:** https://auditoria-ruby-double-v.ondeploy.space/docs

> ✅ El mismo token JWT funciona en producción.

---

## 🐛 Troubleshooting

### ❌ Puertos ocupados
Editar `.env` y cambiar `CLIENTES_PORT`, `FACTURAS_PORT`, `AUDITORIA_PORT`

### ❌ Servicios no se comunican
Verificar que `.env` use nombres de contenedores:
```bash
grep CLIENTES_SERVICE_URL .env
# Debe mostrar: CLIENTES_SERVICE_URL=http://factumarket-clientes:4001
```

### ❌ MongoDB no conecta
```bash
docker ps | grep mongodb
docker logs factumarket-mongodb
```

### ❌ JWT expirado
Ver la sección [🔄 Refresco de JWT](#-refresco-de-jwt-si-el-token-expira) arriba.

---

## ✨ Características del Proyecto

- 🏛️ **Clean Architecture** en Clientes y Facturas
- 📐 **Patrón MVC** en Auditoría
- 🌐 **API REST** con OpenAPI 3.1 y Swagger UI interactivo
- 🔐 **Autenticación JWT** para seguridad service-to-service
- 🐳 **Docker Compose** para orquestación de servicios
- 🧪 **Testing** completo con RSpec
- ⚡ **Comunicación síncrona y asíncrona** entre microservicios
- 💾 **Bases de datos:** SQLite3 + MongoDB
- 📊 **Auditoría** de eventos en tiempo real
- 🚀 **Deployment** en producción con Dokploy

---

## 📚 Documentación Adicional

- 📖 [README.md](../README.md) - Documentación general del proyecto
- 🏗️ [ARQUITECTURA.md](./ARQUITECTURA.md) - Detalles de arquitectura
- 📊 [DIAGRAMAS.md](./DIAGRAMAS.md) - Diagramas del sistema
- 📘 [USO DEL SISTEMA.md](./USO%20DEL%20SISTEMA.md) - Guía completa de uso
- 🧪 [TESTING.md](./TESTING.md) - Documentación de tests

---

> 💡 **¿Problemas o dudas?** Revisa la sección de [Troubleshooting](#-troubleshooting) o consulta los logs con `docker-compose logs`

---

**¡Gracias por evaluar FactuMarket!** 🚀
