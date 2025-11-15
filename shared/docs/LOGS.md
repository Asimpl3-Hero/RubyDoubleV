# 📊 JWT Communication Logs

Sistema de logging para verificar la comunicación JWT entre microservicios.

## Archivo de Log

**Ubicación:** `/tmp/jwt_communication.log` (dentro de cada contenedor)

## Tipos de Eventos

### 1. TOKEN_GENERATED
Se registra cada vez que un servicio genera un token JWT.

```json
{
  "timestamp": "2025-11-14T22:27:15.704Z",
  "type": "TOKEN_GENERATED",
  "service": "test-app",
  "message": "Token JWT generado para test-app"
}
```

### 2. TOKEN_VALIDATED
Se registra cuando un token es validado exitosamente.

```json
{
  "timestamp": "2025-11-14T22:27:15.780Z",
  "type": "TOKEN_VALIDATED",
  "service": "clientes-service",
  "issuer": "test-app",
  "path": "/clientes",
  "success": true,
  "message": "Token de 'test-app' validado exitosamente en 'clientes-service'"
}
```

### 3. TOKEN_REJECTED
Se registra cuando un token es rechazado.

```json
{
  "timestamp": "2025-11-14T22:30:00.000Z",
  "type": "TOKEN_REJECTED",
  "service": "clientes-service",
  "issuer": "unknown",
  "path": "/clientes",
  "success": false,
  "error": "Token expirado"
}
```

### 4. SERVICE_COMMUNICATION
Se registra cada comunicación entre servicios usando AuthenticatedHttpClient.

```json
{
  "timestamp": "2025-11-14T22:27:21.044Z",
  "type": "SERVICE_COMMUNICATION",
  "from": "facturas-service",
  "to": "clientes-service",
  "endpoint": "http://clientes-service:4001/clientes/1",
  "method": "GET",
  "success": true,
  "message": "✅ facturas-service → clientes-service [GET /clientes/1]"
}
```

## Ver Logs

### Desde el host

```bash
# Ver logs de clientes-service
docker exec factumarket-clientes cat /tmp/jwt_communication.log

# Ver logs de facturas-service
docker exec factumarket-facturas cat /tmp/jwt_communication.log

# Ver últimas 10 líneas
docker exec factumarket-clientes tail -10 /tmp/jwt_communication.log
```

### Desde dentro del contenedor

```bash
# Entrar al contenedor
docker exec -it factumarket-clientes sh

# Ver logs
cat /tmp/jwt_communication.log

# Ver en tiempo real
tail -f /tmp/jwt_communication.log
```

## Resumen Estadístico

Usar el método `summary` del JwtLogger:

```bash
docker exec factumarket-clientes sh -c \
  "ruby -r ./shared/jwt_logger -e \"puts JwtLogger.summary\""
```

Salida ejemplo:
```
📊 JWT Communication Summary
═══════════════════════════════════════
Total entries:        16
Tokens generated:     8
Tokens validated:     7 ✅
Tokens rejected:      1 ❌
Service calls:        2
═══════════════════════════════════════
Last activity: {"timestamp":"2025-11-14T22:27:21.044Z",...}
```

## Limpiar Logs

```bash
docker exec factumarket-clientes sh -c \
  "ruby -r ./shared/jwt_logger -e \"JwtLogger.clear_logs\""
```

## Leer Logs Programáticamente

```ruby
# Desde Ruby
require_relative './shared/jwt_logger'

# Últimas 50 líneas
logs = JwtLogger.read_logs(lines: 50)

# Ver resumen
puts JwtLogger.summary

# Limpiar
JwtLogger.clear_logs
```

## Monitoreo en Producción

En producción (Dokploy), los logs estarán en `/tmp/jwt_communication.log` dentro de cada contenedor.

Para acceder:

```bash
# Via docker
docker exec <container-name> cat /tmp/jwt_communication.log

# Via Dokploy logs
# Los logs se pueden ver en el panel de Dokploy si stdout está habilitado
```

## Troubleshooting

### No se generan logs

Verifica que el archivo existe:
```bash
docker exec factumarket-clientes ls -la /tmp/jwt_communication.log
```

### Permisos de escritura

El logger escribe en `/tmp/` que siempre debe tener permisos de escritura.

### Ver errores del logger

```bash
docker exec factumarket-clientes cat /tmp/jwt_logger_errors.log
```

## Formato JSON

Todos los logs están en formato JSON, una línea por evento. Puedes procesarlos fácilmente:

```bash
# Con jq (si está disponible)
docker exec factumarket-clientes cat /tmp/jwt_communication.log | jq '.'

# Con grep
docker exec factumarket-clientes cat /tmp/jwt_communication.log | grep TOKEN_VALIDATED

# Contar eventos por tipo
docker exec factumarket-clientes cat /tmp/jwt_communication.log | \
  grep -o '"type":"[^"]*"' | sort | uniq -c
```

---

**Nota:** Los logs son persistentes mientras el contenedor esté corriendo. Se pierden al reiniciar el contenedor.
