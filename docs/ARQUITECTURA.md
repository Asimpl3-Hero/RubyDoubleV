# Arquitectura del Sistema FactuMarket

## Diagrama de Alto Nivel

```mermaid
graph TB
    subgraph "FactuMarket - Sistema de Facturación Electrónica"
        GW[API Gateway<br/>Opcional]

        subgraph "Microservicios"
            CS[Clientes Service<br/>Puerto 4001<br/>Clean Architecture + MVC]
            FS[Facturas Service<br/>Puerto 4002<br/>Clean Architecture + MVC]
            AS[Auditoría Service<br/>Puerto 4003<br/>MVC + NoSQL]
        end

        subgraph "Capa de Persistencia"
            DBCS[(SQLite/Oracle<br/>CLIENTES<br/>Relacional)]
            DBFS[(SQLite/Oracle<br/>FACTURAS<br/>Relacional)]
            DBAS[(MongoDB<br/>AUDIT_EVENTS<br/>NoSQL)]
        end

        GW -.->|Enruta| CS
        GW -.->|Enruta| FS
        GW -.->|Enruta| AS

        CS -->|Persiste| DBCS
        FS -->|Persiste| DBFS
        AS -->|Persiste| DBAS
    end

    style CS fill:#4CAF50,color:#fff
    style FS fill:#2196F3,color:#fff
    style AS fill:#FF9800,color:#fff
    style DBCS fill:#81C784
    style DBFS fill:#64B5F6
    style DBAS fill:#FFB74D
    style GW fill:#9E9E9E,stroke-dasharray: 5 5
```

## Comunicación entre Servicios

```mermaid
graph LR
    FS[Facturas<br/>Service]
    CS[Clientes<br/>Service]
    AS[Auditoría<br/>Service]

    FS -->|HTTP REST<br/>Valida Cliente| CS
    FS -->|HTTP REST<br/>Registra Evento<br/>async| AS
    CS -->|HTTP REST<br/>Registra Evento<br/>async| AS

    style FS fill:#2196F3,color:#fff
    style CS fill:#4CAF50,color:#fff
    style AS fill:#FF9800,color:#fff
```

### Flujo Detallado de Comunicación

```mermaid
sequenceDiagram
    autonumber
    participant Cliente as Cliente HTTP
    participant FS as Facturas Service
    participant CS as Clientes Service
    participant AS as Auditoría Service
    participant DBF as DB Facturas
    participant DBA as DB Auditoría

    Cliente->>+FS: POST /facturas
    Note over FS: Validar datos de entrada

    FS->>+CS: GET /clientes/:id
    CS-->>-FS: Cliente válido

    Note over FS: Crear entidad Factura<br/>Aplicar reglas de negocio

    FS->>+DBF: INSERT INTO facturas
    DBF-->>-FS: Factura ID

    FS->>AS: POST /auditoria (async)
    Note right of AS: Fire-and-forget<br/>No bloquea respuesta

    FS-->>-Cliente: 201 Factura creada

    AS->>+DBA: INSERT INTO audit_events
    DBA-->>-AS: OK
```

## Principios Arquitectónicos Aplicados

### 1. Microservicios

- **Independencia**: Cada servicio es independiente y puede desplegarse por separado
- **Escalabilidad**: Los servicios pueden escalar de forma independiente según demanda
- **Despliegue Autónomo**: Cada servicio tiene su propio ciclo de vida
- **Base de Datos por Servicio**: Cada microservicio tiene su propia base de datos

### 2. Clean Architecture

Aplicada en **Clientes Service** y **Facturas Service**:

```mermaid
graph TD
    subgraph "Clean Architecture - Capas"
        PL[Presentation Layer<br/>Controllers MVC - API REST<br/>app/controllers/]
        AL[Application Layer<br/>Use Cases - Casos de Uso<br/>app/application/use_cases/]
        DL[Domain Layer<br/>Entities + Repository Interfaces<br/>app/domain/entities/ + repositories/]
        IL[Infrastructure Layer<br/>Repository Implementations + Database<br/>app/infrastructure/persistence/ + app/models/]
    end

    Request[HTTP Request] --> PL
    PL --> AL
    AL --> DL
    DL -.->|Interface| IL
    IL --> DB[(Database<br/>SQLite/Oracle)]

    PL --> Response[HTTP Response JSON]

    style PL fill:#E3F2FD
    style AL fill:#FFF3E0
    style DL fill:#E8F5E9
    style IL fill:#FCE4EC
    style DB fill:#F3E5F5
```

**Dependencias:**
```mermaid
graph LR
    P[Presentation] -->|depende| A[Application]
    A -->|depende| D[Domain]
    I[Infrastructure] -->|implementa| D
    I -.->|no depende| A

    style D fill:#4CAF50,color:#fff
    style A fill:#FF9800,color:#fff
    style P fill:#2196F3,color:#fff
    style I fill:#9C27B0,color:#fff
```

**Ventajas**:
- Lógica de negocio independiente de frameworks
- Fácil de testear (pruebas unitarias de dominio)
- Flexibilidad para cambiar tecnologías de infraestructura
- Separación clara de responsabilidades

### 3. Patrón MVC (Model-View-Controller)

```mermaid
graph LR
    Client[API Consumer] -->|HTTP Request| C[Controller]
    C -->|Query| M[Model]
    M -->|SQL| DB[(Database)]
    DB -->|Result| M
    M -->|Data| C
    C -->|JSON Response| V[View/JSON]
    V --> Client

    style C fill:#2196F3,color:#fff
    style M fill:#4CAF50,color:#fff
    style V fill:#FF9800,color:#fff
    style DB fill:#9C27B0,color:#fff
```

- **Model**: Representación de datos y lógica de negocio (ActiveRecord models)
- **View**: Respuestas JSON (API REST)
- **Controller**: Maneja requests HTTP y orquesta la lógica

### 4. Estrategia de Persistencia

#### Datos Transaccionales (Oracle/SQLite)

- **Clientes**: Información de clientes (CRUD)
- **Facturas**: Facturas electrónicas con relaciones

**Características**:
- ACID transactions
- Relaciones entre entidades
- Consultas complejas con JOINs
- Integridad referencial

#### Datos de Auditoría (MongoDB)

- **Audit Events**: Registro de todas las operaciones

**Características**:
- Alta velocidad de escritura
- Esquema flexible
- Consultas por rangos de fecha eficientes
- No requiere relaciones complejas

## Flujo de Comunicación

### Flujo 1: Crear Cliente

```mermaid
sequenceDiagram
    autonumber
    participant Usuario
    participant Controller as ClientesController
    participant UseCase as CreateCliente
    participant Repo as ClienteRepository
    participant DB as SQLite/Oracle
    participant Audit as Auditoría Service

    Usuario->>+Controller: POST /clientes
    Controller->>+UseCase: execute(datos)
    UseCase->>UseCase: Crear entidad Cliente<br/>Validar reglas de negocio
    UseCase->>+Repo: save(cliente)
    Repo->>+DB: INSERT INTO clientes
    DB-->>-Repo: cliente_id
    Repo-->>-UseCase: Cliente guardado
    UseCase->>Audit: POST /auditoria (async)
    Note right of Audit: No bloquea respuesta
    UseCase-->>-Controller: Cliente
    Controller-->>-Usuario: 201 Created + JSON
```

### Flujo 2: Crear Factura

```mermaid
sequenceDiagram
    autonumber
    participant Usuario
    participant Controller as FacturasController
    participant UseCase as CreateFactura
    participant Validator as ClienteValidator
    participant ClienteSvc as Clientes Service
    participant Repo as FacturaRepository
    participant DB as SQLite/Oracle
    participant Audit as Auditoría Service

    Usuario->>+Controller: POST /facturas
    Controller->>+UseCase: execute(datos)

    Note over UseCase,ClienteSvc: Validación de Cliente
    UseCase->>+Validator: cliente_exists?(id)
    Validator->>+ClienteSvc: GET /clientes/:id
    ClienteSvc-->>-Validator: Cliente data
    Validator-->>-UseCase: Cliente válido

    UseCase->>UseCase: Crear entidad Factura<br/>Validar reglas de negocio<br/>Generar número de factura

    UseCase->>+Repo: save(factura)
    Repo->>+DB: INSERT INTO facturas
    DB-->>-Repo: factura_id
    Repo-->>-UseCase: Factura guardada

    UseCase->>Audit: POST /auditoria (async)
    Note right of Audit: Fire-and-forget

    UseCase-->>-Controller: Factura
    Controller-->>-Usuario: 201 Created + JSON
```

## Consistencia entre Servicios

### Eventual Consistency

El sistema utiliza **consistencia eventual** para los eventos de auditoría:

- Las operaciones principales (CRUD) se ejecutan de forma síncrona
- Los eventos de auditoría se registran de forma asíncrona (fire-and-forget)
- Si falla el registro de auditoría, no afecta la operación principal

### Validación Síncrona

La validación de cliente en el servicio de Facturas es **síncrona**:

- Se hace una llamada HTTP al servicio de Clientes
- Si el cliente no existe, la factura no se crea
- Garantiza integridad referencial entre servicios

## Tecnologías Utilizadas

- **Ruby**: Lenguaje de programación
- **Sinatra**: Framework web ligero
- **Puma**: Servidor de aplicaciones
- **ActiveRecord**: ORM para bases de datos relacionales
- **SQLite**: Base de datos en desarrollo (reemplazable por Oracle en producción)
- **MongoDB**: Base de datos NoSQL para auditoría
- **HTTParty**: Cliente HTTP para comunicación entre servicios
- **RSpec**: Framework de testing
- **Docker**: Containerización

## Escalabilidad y Mejoras Futuras

### Message Queue (Recomendado para Producción)

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│ Clientes │────>│ RabbitMQ │────>│Auditoría │
│ Service  │     │   / Kafka│     │ Service  │
└──────────┘     └──────────┘     └──────────┘
```

**Ventajas**:
- Desacoplamiento total
- Tolerancia a fallos
- Reintento automático
- Escalabilidad horizontal

### API Gateway

```
┌──────────────┐
│ API Gateway  │
│   (Kong/     │
│   Traefik)   │
└──────────────┘
       │
       ├─> /clientes/*  → Clientes Service
       ├─> /facturas/*  → Facturas Service
       └─> /auditoria/* → Auditoría Service
```

**Ventajas**:
- Punto único de entrada
- Autenticación centralizada
- Rate limiting
- Logging y monitoreo

### Service Discovery

Para ambientes cloud:
- **Consul** o **Eureka** para descubrimiento de servicios
- Health checks automáticos
- Load balancing dinámico

## Integración con DIAN (Futura)

El sistema está preparado para integración con la DIAN:

```
┌──────────┐     ┌──────────────┐     ┌──────────┐
│ Facturas │────>│ DIAN Adapter │────>│   DIAN   │
│ Service  │     │   Service    │     │   API    │
└──────────┘     └──────────────┘     └──────────┘
```

Se puede agregar un nuevo microservicio que:
- Reciba facturas del servicio de Facturas
- Transforme al formato XML requerido por DIAN
- Envíe a la API de la DIAN
- Registre el resultado en Auditoría
