# Arquitectura del Sistema FactuMarket

Sistema de microservicios para facturación electrónica con Clean Architecture y MVC.

---

## Arquitectura General

```mermaid
graph TB
    subgraph "Microservicios"
        CS[Clientes Service<br/>:4001]
        FS[Facturas Service<br/>:4002]
        AS[Auditoría Service<br/>:4003]
    end

    subgraph "Bases de Datos"
        SQL[(SQLite/Oracle<br/>Transaccional)]
        MONGO[(MongoDB<br/>Auditoría)]
    end

    FS -->|Valida Cliente| CS
    CS -->|Eventos| AS
    FS -->|Eventos| AS
    CS --> SQL
    FS --> SQL
    AS --> MONGO

    style CS fill:#51cf66,stroke:#2f9e44,color:#fff
    style FS fill:#4dabf7,stroke:#1971c2,color:#fff
    style AS fill:#ffd43b,stroke:#f59f00,color:#000
```

**Principios:**
- **Microservicios independientes** - Cada uno con su base de datos
- **Comunicación REST** - HTTP para validaciones (síncrono) y eventos (asíncrono)
- **Consistencia eventual** - Auditoría no bloquea operaciones principales

---

## Clean Architecture (Clientes & Facturas)

```mermaid
graph TD
    subgraph "Capas - Flujo de Dependencias"
        PL[Presentation<br/>Controllers - API REST<br/>app/controllers/]
        AL[Application<br/>Use Cases<br/>app/application/use_cases/]
        DL[Domain<br/>Entities + Interfaces<br/>app/domain/]
        IL[Infrastructure<br/>Repository Implementations<br/>app/infrastructure/ + models/]
    end

    Request[HTTP Request] --> PL
    PL --> AL
    AL --> DL
    DL -.->|implementa| IL
    IL --> DB[(Database)]
    PL --> Response[JSON Response]

    style PL fill:#4dabf7,stroke:#1971c2,color:#fff
    style AL fill:#ffd43b,stroke:#f59f00,color:#000
    style DL fill:#51cf66,stroke:#2f9e44,color:#fff
    style IL fill:#ff6b6b,stroke:#c92a2a,color:#fff
```

**Regla de Dependencias:** Solo hacia adentro (Domain no depende de nada)

**Ventajas:**
- Lógica de negocio independiente de frameworks
- Fácil de testear (domain sin dependencias externas)
- Flexible para cambiar tecnologías

---

## Flujo: Crear Factura

```mermaid
sequenceDiagram
    participant Client
    participant Facturas
    participant Clientes
    participant DB
    participant Auditoría

    Client->>Facturas: POST /facturas
    Note over Facturas: Validar datos

    Facturas->>Clientes: GET /clientes/:id
    Clientes-->>Facturas: Cliente válido

    Note over Facturas: Crear entidad<br/>Aplicar reglas

    Facturas->>DB: INSERT factura
    DB-->>Facturas: OK

    Facturas->>Auditoría: POST /auditoria (async)
    Note right of Auditoría: Fire-and-forget

    Facturas-->>Client: 201 Created
```

**Pasos:**
1. Validar datos de entrada
2. Verificar cliente existe (síncrono)
3. Crear factura en DB
4. Registrar evento en auditoría (asíncrono)
5. Responder al cliente

---

## Patrón MVC

```mermaid
graph LR
    Client[API Consumer] -->|Request| C[Controller]
    C -->|Use Case| M[Model/Repository]
    M -->|SQL| DB[(Database)]
    DB -->|Data| M
    M -->|Entity| C
    C -->|JSON| Client

    style C fill:#4dabf7,stroke:#1971c2,color:#fff
    style M fill:#51cf66,stroke:#2f9e44,color:#fff
    style DB fill:#ffd43b,stroke:#f59f00,color:#000
```

**Componentes:**
- **Controller** (`app/controllers/`) - Maneja HTTP requests
- **Model** (`app/models/`) - ActiveRecord, acceso a datos
- **View** - Respuestas JSON (API REST)

---

## Estrategia de Persistencia

### Datos Transaccionales → SQLite/Oracle

**Clientes & Facturas**
- ACID transactions
- Relaciones entre entidades
- Integridad referencial

### Datos de Auditoría → MongoDB

**Eventos del Sistema**
- Alta velocidad de escritura
- Esquema flexible
- Consultas por rangos de fecha eficientes
- Sin relaciones complejas

---

## Comunicación entre Servicios

### Síncrona (Crítica)
```
Facturas → GET /clientes/:id → Clientes
```
**Uso:** Validación de cliente antes de crear factura
**Timeout:** 5 segundos
**Error:** 422 si cliente no existe

### Asíncrona (No Crítica)
```
Clientes/Facturas → POST /auditoria → Auditoría
```
**Uso:** Registro de eventos
**Patrón:** Fire-and-forget
**Error:** No bloquea operación principal

---

## Stack Tecnológico

| Componente | Tecnología |
|------------|------------|
| Lenguaje | Ruby 3.2+ |
| Framework Web | Sinatra |
| Servidor | Puma |
| ORM | ActiveRecord |
| DB Relacional | SQLite (dev) / Oracle (prod) |
| DB NoSQL | MongoDB |
| HTTP Client | HTTParty |
| Testing | RSpec + WebMock |
| Containerización | Docker + Docker Compose |
| API Docs | OpenAPI 3.0 + Swagger UI |

---

## Mejoras Futuras

### 1. Message Queue para Auditoría
```
Servicios → RabbitMQ/Kafka → Auditoría
```
**Beneficios:** Desacoplamiento total, reintentos automáticos

### 2. API Gateway
```
Kong/Traefik → Router por path → Microservicios
```
**Beneficios:** Autenticación centralizada, rate limiting

### 3. Service Discovery
```
Consul/Eureka → Health checks + Load balancing
```
**Beneficios:** Escalabilidad automática en cloud

### 4. Integración DIAN
```
Facturas → DIAN Adapter (nuevo servicio) → API DIAN
```
**Funcionalidad:** Transformar a XML, firmar, enviar a autoridad tributaria

---

**Última actualización:** Enero 2025
