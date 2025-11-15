# FactuMarket - Sistema de Facturación Electrónica

![Ruby](https://img.shields.io/badge/Ruby-3.2+-CC342D?style=for-the-badge&logo=ruby&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Swagger](https://img.shields.io/badge/Swagger-85EA2D?style=for-the-badge&logo=swagger&logoColor=black)
![MongoDB](https://img.shields.io/badge/MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)

> Sistema de microservicios para facturación electrónica construido con Ruby, aplicando **Clean Architecture** y **patrón MVC**, con bases de datos SQLite (transaccional) y MongoDB (auditoría).

## 🚀 Inicio Rápido

```bash
# Clonar el repositorio
git clone <repository-url>
cd RubyDoubleV

# Configurar variables de entorno
cp .env.example .env

# Levantar servicios con Docker
docker-compose up --build
```

**🌐 Servicios en Producción:**

| Servicio      | URL                                            | Swagger Docs                                                 |
| ------------- | ---------------------------------------------- | ------------------------------------------------------------ |
| **Clientes**  | https://clientes-ruby-double-v.ondeploy.space  | [/docs](https://clientes-ruby-double-v.ondeploy.space/docs)  |
| **Facturas**  | https://factura-ruby-double-v.ondeploy.space   | [/docs](https://factura-ruby-double-v.ondeploy.space/docs)   |
| **Auditoría** | https://auditoria-ruby-double-v.ondeploy.space | [/docs](https://auditoria-ruby-double-v.ondeploy.space/docs) |

### 📊 Conexión a MongoDB

**Local (Desarrollo):**

```
mongodb://admin:factumarket_secure_2025@localhost:27017/?authSource=admin
```

| Parámetro         | Valor                     |
| ----------------- | ------------------------- |
| **Usuario**       | `admin`                   |
| **Password**      | `factumarket_secure_2025` |
| **Base de datos** | `auditoria_db`            |
| **Auth Source**   | `admin`                   |

**Herramientas recomendadas:**

- [MongoDB Compass](https://www.mongodb.com/products/compass) - GUI oficial
- [Studio 3T](https://studio3t.com/) - Cliente avanzado

**Colecciones disponibles:**

- `audit_events` - Registros de auditoría del sistema

## ✨ Características Principales

- ✅ Arquitectura de microservicios independientes
- ✅ Clean Architecture + patrón MVC
- ✅ API REST con documentación Swagger/OpenAPI 3.0
- ✅ Bases de datos: SQLite + MongoDB
- ✅ Testing unitario e integración
- ✅ Despliegue con Docker

---

## 📊 Estrategia de Persistencia

| Servicio              | Base de Datos | Propósito              |
| --------------------- | ------------- | ---------------------- |
| **Clientes/Facturas** | SQLite        | Transaccional (ACID)   |
| **Auditoría**         | MongoDB       | Eventos y logs (NoSQL) |

Esta arquitectura polglota demuestra conocimiento de:

- Bases de datos SQL y NoSQL
- Patrón CQRS
- Event Sourcing
- Principio de inversión de dependencias (SOLID)

---

## 📚 Documentación

| Documento                                             | Descripción                                                               |
| ----------------------------------------------------- | ------------------------------------------------------------------------- |
| 📖 [**Uso del Sistema**](docs/USO%20DEL%20SISTEMA.md) | Instalación detallada, ejemplos de API, flujos completos y casos de error |
| 🏗️ [**Arquitectura**](docs/ARQUITECTURA.md)           | Patrones Clean Architecture, estructura y decisiones de diseño            |
| 🧪 [**Testing**](docs/TESTING.md)                     | Suite completa de pruebas unitarias, integración y cobertura              |
| 📊 [**Diagramas**](docs/DIAGRAMAS.md)                 | Diagramas de arquitectura, secuencia y flujos del sistema                 |

## 🛠️ Requisitos

**Con Docker (Recomendado):**

- Docker >= 20.x
- Docker Compose >= 2.x

**Sin Docker:**

- Ruby >= 3.2
- SQLite3
- MongoDB >= 5.0

> 💡 Para instrucciones detalladas de instalación, ver [Uso del Sistema](docs/USO%20DEL%20SISTEMA.md)

## 🛠️ Stack Tecnológico

- **Backend**: Ruby 3.2+ con Sinatra
- **Bases de Datos**: SQLite + MongoDB
- **Testing**: RSpec + WebMock
- **Documentación**: OpenAPI 3.0 + Swagger UI
- **Deployment**: Docker + Docker Compose

## 👨‍💻 Autor

Desarrollado por **Justin Hernandez Tobinson** como prueba técnica para Double V Partners.

---

> 📌 **Nota**: Este README es una vista general del proyecto. Para guías detalladas de instalación, uso y ejemplos de API, consulta la [documentación completa](docs/).
