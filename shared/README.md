# 📁 Shared - Código Compartido entre Microservicios

Carpeta de código y utilidades compartidas entre todos los microservicios de FactuMarket.

## 📂 Estructura

```
shared/
├── jwt/                      # Módulos de autenticación JWT
│   ├── service_jwt.rb                   # Generador y validador de tokens
│   ├── jwt_validation_middleware.rb     # Middleware Rack para validación
│   ├── authenticated_http_client.rb     # Cliente HTTP con JWT automático
│   └── jwt_logger.rb                    # Logger de comunicación JWT
│
├── docs/                     # Documentación
│   ├── README.md                        # Guía JWT completa
│   └── LOGS.md                          # Sistema de logs JWT
│
└── README.md                 # Este archivo
```

## 🔐 Módulo JWT (`jwt/`)

Sistema completo de autenticación service-to-service usando JWT.

### Archivos

- **`service_jwt.rb`** - Core del sistema JWT
  - Genera tokens firmados con HMAC-SHA256
  - Valida tokens y verifica expiración
  - Expira tokens en 5 minutos

- **`jwt_validation_middleware.rb`** - Middleware Rack
  - Protege endpoints automáticamente
  - Excepciones: `/health`, `/docs`, `/api-docs`
  - Retorna 401 si no hay token válido

- **`authenticated_http_client.rb`** - Cliente HTTP
  - Agrega JWT automáticamente a requests
  - Reemplaza HTTParty estándar
  - Para comunicación entre servicios

- **`jwt_logger.rb`** - Sistema de logging
  - Registra generación de tokens
  - Registra validaciones (exitosas/fallidas)
  - Registra comunicación inter-servicio
  - Logs en `/tmp/jwt_communication.log`

### Uso

```ruby
# En config.ru
require_relative './shared/jwt/jwt_validation_middleware'
use JwtValidationMiddleware::Validator

# En servicios que llaman a otros
require_relative '../../../shared/jwt/authenticated_http_client'
AuthenticatedHttpClient::Client.get(url)
```

## 📚 Documentación (`docs/`)

- **`README.md`** - Guía completa de JWT
  - Cómo funciona
  - Configuración
  - Ejemplos de uso
  - Troubleshooting
  - Deployment

- **`LOGS.md`** - Sistema de logs
  - Tipos de eventos
  - Cómo ver logs
  - Resumen estadístico
  - Formato JSON

## 🚀 Deployment

### Desarrollo Local

Los archivos se montan como volumen en `docker-compose.yml`:

```yaml
volumes:
  - ./shared:/app/shared
```

### Producción (Dokploy)

Los Dockerfiles copian la carpeta completa durante el build:

```dockerfile
# La carpeta shared/ se preserva automáticamente
COPY . .
RUN if [ -d "/app/clientes-service" ]; then \
      cp -r /app/shared /tmp/shared_backup && \
      ... \
      mv /tmp/shared_backup /app/shared; \
    fi
```

## 📋 Variables de Entorno Requeridas

```bash
JWT_SECRET_KEY=<secret-key-64-chars>  # Misma en TODOS los servicios
SERVICE_NAME=<service-name>           # Único por servicio
```

## ⚙️ Agregar Nuevas Utilidades Compartidas

1. Crear subcarpeta si es categoría nueva: `shared/nueva_categoria/`
2. Agregar archivos Ruby
3. Documentar en este README
4. Actualizar referencias en servicios

## 🔗 Enlaces Rápidos

- [Guía JWT Completa](docs/README.md)
- [Sistema de Logs](docs/LOGS.md)

---

**Última actualización:** 2025-11-14
