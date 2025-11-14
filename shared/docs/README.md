# 🔐 JWT Service-to-Service Authentication

Autenticación JWT para comunicación entre microservicios de FactuMarket.

## ¿Qué es esto?

Sistema de autenticación **service-to-service** usando JWT. No hay usuarios ni login, solo validación automática entre servicios.

**Características:**
- ✅ Tokens generados y validados automáticamente
- ✅ Sin base de datos (stateless)
- ✅ Expiran en 5 minutos
- ✅ Firmados con HMAC-SHA256

## Archivos

```
shared/
├── service_jwt.rb                    # Genera y valida tokens JWT
├── jwt_validation_middleware.rb     # Middleware Rack que valida requests
└── authenticated_http_client.rb     # Cliente HTTP con JWT automático
```

## Cómo funciona en tus microservicios

### 1. Middleware protege endpoints

Todos los endpoints requieren JWT excepto `/health`, `/docs`, `/api-docs`:

```ruby
# clientes-service/config.ru
use JwtValidationMiddleware::Validator, exempt_paths: ['/health', '/docs', '/api-docs']
```

**Resultado:**
- ✅ `GET /health` → Funciona sin JWT
- ❌ `GET /clientes` → Requiere JWT (401 si no lo tiene)
- ✅ `GET /clientes` con JWT → Funciona

### 2. Cliente HTTP agrega JWT automáticamente

Cuando un servicio llama a otro, `AuthenticatedHttpClient` agrega el JWT:

```ruby
# facturas-service/app/domain/services/cliente_validator.rb
response = AuthenticatedHttpClient::Client.get(
  "#{@clientes_service_url}/clientes/#{cliente_id}",
  timeout: 5
)
```

Esto internamente:
1. Genera JWT con `ServiceJWT.generate_for_current_service`
2. Agrega header `Authorization: Bearer <token>`
3. Hace el request

## Configuración

### Variables de entorno requeridas

```bash
# .env
JWT_SECRET_KEY=160b6ba480729089b07d54020388926db99330c793e77fb6530262f973121077
```

```yaml
# docker-compose.yml (cada servicio)
environment:
  - SERVICE_NAME=clientes-service    # Nombre único
  - JWT_SECRET_KEY=${JWT_SECRET_KEY} # Misma key en TODOS
```

**⚠️ IMPORTANTE:** La misma `JWT_SECRET_KEY` debe estar en TODOS los servicios.

### Generar nueva secret key

```bash
ruby -rsecurerandom -e 'puts SecureRandom.hex(32)'
```

## Uso

### Generar token manualmente (testing)

```bash
# Desde contenedor
docker exec factumarket-clientes sh -c \
  "ruby -r ./shared/service_jwt -e \"puts ServiceJWT.generate(service_name: 'test')\""
```

### Probar endpoint con JWT

```bash
# Sin JWT (falla)
curl http://localhost:4001/clientes
# → {"success":false,"error":"Token requerido"}

# Con JWT (funciona)
TOKEN=$(docker exec factumarket-clientes sh -c \
  "ruby -r ./shared/service_jwt -e \"puts ServiceJWT.generate(service_name: 'test')\"")

curl -H "Authorization: Bearer $TOKEN" http://localhost:4001/clientes
# → {"success":true,"data":[...],"count":1}
```

## Estructura del Token

```json
{
  "iss": "facturas-service",  // Emisor (SERVICE_NAME)
  "iat": 1705320000,          // Timestamp de emisión
  "exp": 1705320300,          // Expira en 5 minutos
  "jti": "uuid-123..."        // ID único del token
}
```

## Troubleshooting

### Error: "JWT_SECRET_KEY not set"

Verifica que `.env` tenga la variable:

```bash
cat .env | grep JWT_SECRET_KEY
docker-compose exec clientes-service env | grep JWT_SECRET_KEY
```

### Error: "Token requerido"

No estás usando `AuthenticatedHttpClient`:

```ruby
# ❌ MAL
HTTParty.get(url)

# ✅ BIEN
AuthenticatedHttpClient::Client.get(url)
```

### Error: "Token inválido"

**Causa común:** Secret keys diferentes entre servicios.

```bash
# Verificar que sean idénticas
docker-compose exec clientes-service env | grep JWT_SECRET_KEY
docker-compose exec facturas-service env | grep JWT_SECRET_KEY
```

### Error: "Token expirado"

Tokens duran 5 minutos. `AuthenticatedHttpClient` genera uno nuevo en cada request automáticamente.

## Seguridad

### ✅ Protege contra
- Acceso no autorizado (sin secret key, no puedes generar tokens)
- Requests externos maliciosos
- Replay attacks limitados (expiración de 5 min)

### ❌ NO protege contra
- Man-in-the-Middle (usa HTTPS en producción)
- Compromiso de secret key (rotarla periódicamente)

### Best Practices

1. **Secret key seguro:** Mínimo 32 caracteres hex
2. **HTTPS en producción:** Siempre
3. **Diferentes keys por ambiente:** dev vs prod
4. **Rotar key:** Cada 3-6 meses en producción
5. **Nunca loguear la secret key**

## Deployment en Dokploy

Los Dockerfiles ya están configurados para copiar la carpeta `shared/` durante el build.

**Paso único:** Agrega `JWT_SECRET_KEY` en las variables de entorno de Dokploy para cada servicio:

```
JWT_SECRET_KEY=160b6ba480729089b07d54020388926db99330c793e77fb6530262f973121077
```

---

**Versión:** 1.0.0
**Última actualización:** 2025-01-14
