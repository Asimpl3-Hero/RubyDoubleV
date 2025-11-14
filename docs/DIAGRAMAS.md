# 📊 Diagramas del Sistema - FactuMarket

> Representaciones visuales de la arquitectura, flujos y componentes del sistema.

---

## 📋 Tabla de Contenidos

- [Arquitectura General](#-arquitectura-general)
- [Flujo: Crear Factura](#-flujo-crear-factura)
- [Clean Architecture](#-clean-architecture)
- [Comunicación entre Servicios](#-comunicación-entre-servicios)

---

## 🏗️ Arquitectura General

```mermaid
graph TB
    subgraph "Cliente HTTP"
        USER[🧑 Usuario/API Client]
    end

    subgraph "Microservicios"
        CS[🟢 Clientes Service<br/>:4001<br/>Clean Architecture]
        FS[🔵 Facturas Service<br/>:4002<br/>Clean Architecture]
        AS[🟡 Auditoría Service<br/>:4003<br/>Event Store]
    end

    subgraph "Bases de Datos"
        SQL[(SQLite/Oracle<br/>Transaccional)]
        MONGO[(MongoDB<br/>Auditoría)]
    end

    USER --> CS
    USER --> FS
    USER --> AS

    FS -->|Valida Cliente| CS
    CS -->|Eventos| AS
    FS -->|Eventos| AS

    CS --> SQL
    FS --> SQL
    AS --> MONGO

    style CS fill:#51cf66,stroke:#2f9e44,color:#fff
    style FS fill:#4dabf7,stroke:#1971c2,color:#fff
    style AS fill:#ffd43b,stroke:#f59f00,color:#000
    style USER fill:#868e96,stroke:#495057,color:#fff
```

**Características:**
- ✅ 3 microservicios independientes
- ✅ Cada servicio con su propia base de datos
- ✅ Comunicación REST entre servicios
- ✅ Auditoría asíncrona (no bloquea operaciones)

---

## 🔄 Flujo: Crear Factura

```mermaid
sequenceDiagram
    participant Client as 🧑 Cliente
    participant Facturas as 🔵 Facturas Service
    participant Clientes as 🟢 Clientes Service
    participant DB as 💾 SQLite
    participant Auditoría as 🟡 Auditoría Service
    participant Mongo as 🍃 MongoDB

    Client->>Facturas: POST /facturas<br/>{cliente_id, monto, items}

    Note over Facturas: 1️⃣ Validar datos básicos<br/>(monto > 0, fecha válida)

    Facturas->>Clientes: 2️⃣ GET /clientes/:id
    alt Cliente existe
        Clientes-->>Facturas: ✅ 200 OK {cliente}
    else Cliente no existe
        Clientes-->>Facturas: ❌ 404 Not Found
        Facturas-->>Client: 422 Error
    end

    Note over Facturas: 3️⃣ Aplicar reglas de negocio<br/>Generar número de factura

    Facturas->>DB: 4️⃣ INSERT factura
    DB-->>Facturas: ✅ Factura creada

    Facturas->>Auditoría: 5️⃣ POST /auditoria<br/>(async, fire-and-forget)
    Note right of Auditoría: No bloquea<br/>la respuesta
    Auditoría->>Mongo: Registrar evento

    Facturas-->>Client: ✅ 201 Created<br/>{factura}
```

**Puntos clave:**
1. Validación en capas: datos → cliente existe → reglas de negocio
2. Comunicación síncrona para validar cliente (timeout 5s)
3. Comunicación asíncrona para auditoría (no bloquea)
4. Transacción en base de datos antes de responder

---

## 🎯 Clean Architecture

```mermaid
graph TD
    subgraph "🎯 Presentation Layer"
        HTTP[HTTP Request]
        CTRL[Controller<br/>app/controllers/]
        JSON[JSON Response]
    end

    subgraph "📋 Application Layer"
        UC[Use Cases<br/>app/application/use_cases/]
    end

    subgraph "🧠 Domain Layer"
        ENT[Entities<br/>app/domain/entities/]
        REPO_INT[Repository Interfaces<br/>app/domain/repositories/]
    end

    subgraph "🔌 Infrastructure Layer"
        REPO_IMPL[Repository Implementation<br/>app/infrastructure/persistence/]
        DB[(Database<br/>SQLite/MongoDB)]
    end

    HTTP --> CTRL
    CTRL --> UC
    UC --> ENT
    UC --> REPO_INT
    REPO_INT -.->|implements| REPO_IMPL
    REPO_IMPL --> DB
    CTRL --> JSON

    style CTRL fill:#4dabf7,stroke:#1971c2,color:#fff
    style UC fill:#ffd43b,stroke:#f59f00,color:#000
    style ENT fill:#51cf66,stroke:#2f9e44,color:#fff
    style REPO_IMPL fill:#ff6b6b,stroke:#c92a2a,color:#fff
```

**Regla de dependencias:**
- ⬇️ Presentation → Application → Domain
- ⬆️ Domain NO depende de nada
- 🔄 Infrastructure implementa interfaces del Domain

**Beneficios:**
- ✅ Lógica de negocio independiente de frameworks
- ✅ Fácil testing unitario (sin dependencias externas)
- ✅ Cambiar BD o framework sin afectar lógica

---

## 🌐 Comunicación entre Servicios

```mermaid
graph LR
    subgraph "Tipos de Comunicación"
        SYNC[🔄 Síncrona<br/>Request-Response<br/>Timeout: 5s]
        ASYNC[⚡ Asíncrona<br/>Fire-and-Forget<br/>Sin timeout]
    end

    subgraph "Ejemplos"
        F[Facturas]
        C[Clientes]
        A[Auditoría]
    end

    F -->|GET /clientes/:id| C
    C -.->|"200 OK {cliente}"| F

    F -->|POST /auditoria| A

    Note1[Bloquea hasta<br/>recibir respuesta]
    Note2[No espera<br/>respuesta]

    style SYNC fill:#4dabf7,stroke:#1971c2,color:#fff
    style ASYNC fill:#51cf66,stroke:#2f9e44,color:#fff
    style Note1 fill:#fff,stroke:#495057,color:#000
    style Note2 fill:#fff,stroke:#495057,color:#000
```

| Tipo | Uso | Timeout | Bloquea | Manejo de Error |
|------|-----|---------|---------|-----------------|
| **Síncrona** | Validar cliente antes de crear factura | 5s | ✅ Sí | Devuelve error al cliente |
| **Asíncrona** | Registrar evento de auditoría | - | ❌ No | Continúa aunque falle |

---

## 📝 Notas

- **Ver diagramas en vivo**: Los diagramas Mermaid se renderizan automáticamente en GitHub
- **Editor local**: Usar extensión "Markdown Preview Mermaid Support" en VS Code
- **Probar cambios**: https://mermaid.live/

---

**📚 Documentación relacionada:**
- [Arquitectura](ARQUITECTURA.md) - Detalles técnicos de la arquitectura
- [Uso del Sistema](USO%20DEL%20SISTEMA.md) - Cómo usar las APIs
- [Testing](TESTING.md) - Pruebas unitarias e integración
