# Guía de Testing - FactuMarket

## Índice

- [Estrategia de Testing](#estrategia-de-testing)
- [Pruebas Unitarias](#pruebas-unitarias)
- [Pruebas de Integración](#pruebas-de-integración)
- [Ejecución de Tests](#ejecución-de-tests)
- [Mocking y Stubs](#mocking-y-stubs)
- [Buenas Prácticas](#buenas-prácticas)

---

## Estrategia de Testing

El proyecto FactuMarket implementa una **estrategia de testing en pirámide**:

```mermaid
graph TB
    subgraph "Testing Pyramid"
        E2E[E2E Tests<br/>Manual via Swagger UI<br/>Pocos tests, alta cobertura]
        INT[Integration Tests<br/>Service Communication<br/>Tests moderados]
        UNIT[Unit Tests<br/>Domain Logic<br/>Muchos tests, rápidos]
    end

    UNIT --> INT
    INT --> E2E

    style E2E fill:#ff6b6b,stroke:#c92a2a,color:#fff
    style INT fill:#4dabf7,stroke:#1971c2,color:#fff
    style UNIT fill:#51cf66,stroke:#2f9e44,color:#fff
```

### Niveles de Testing

```mermaid
graph LR
    A[Unit Tests] --> B[Integration Tests]
    B --> C[E2E Tests]

    A1[Domain Logic<br/>Sin dependencias] -.-> A
    B1[Service Communication<br/>HTTP Mocks] -.-> B
    C1[Manual Testing<br/>Swagger UI] -.-> C

    style A fill:#51cf66,stroke:#2f9e44,color:#fff
    style B fill:#4dabf7,stroke:#1971c2,color:#fff
    style C fill:#ff6b6b,stroke:#c92a2a,color:#fff
```

**Distribución de Tests:**

- 🟢 **70%** - Unit Tests (Base)
- 🔵 **20%** - Integration Tests (Medio)
- 🔴 **10%** - E2E Tests (Tope)

---

## Pruebas Unitarias

### Objetivo

Validar la lógica de dominio sin dependencias externas (bases de datos, HTTP, etc.).

### Arquitectura de Tests Unitarios

```mermaid
graph TB
    subgraph "Test Environment"
        TEST[RSpec Test]
    end

    subgraph "Domain Layer - Isolated"
        ENT[Domain::Entities::Cliente]
        VAL[Validations]
        LOGIC[Business Logic]
    end

    TEST -->|Test| ENT
    ENT --> VAL
    ENT --> LOGIC

    DB[(Database)]
    HTTP[HTTP Services]

    ENT -.->|No Access| DB
    ENT -.->|No Access| HTTP

    style TEST fill:#51cf66,stroke:#2f9e44,color:#fff
    style ENT fill:#ffd43b,stroke:#f59f00,color:#000
    style DB fill:#ddd,stroke:#999,color:#666
    style HTTP fill:#ddd,stroke:#999,color:#666
```

### Ubicación

```
clientes-service/spec/domain/
facturas-service/spec/domain/
```

### Ejemplo: Test de Entidad Cliente

```ruby
# spec/domain/entities/cliente_spec.rb
RSpec.describe Domain::Entities::Cliente do
  describe '#initialize' do
    context 'with valid attributes' do
      it 'creates a cliente successfully' do
        cliente = described_class.new(
          nombre: 'Empresa ABC S.A.',
          identificacion: '900123456',
          correo: 'contacto@empresaabc.com',
          direccion: 'Calle 123 #45-67'
        )

        expect(cliente.nombre).to eq('Empresa ABC S.A.')
        expect(cliente.identificacion).to eq('900123456')
      end
    end

    context 'with invalid attributes' do
      it 'raises ArgumentError when nombre is empty' do
        expect {
          described_class.new(
            nombre: '',
            identificacion: '900123456',
            correo: 'contacto@empresaabc.com',
            direccion: 'Calle 123'
          )
        }.to raise_error(ArgumentError, 'Nombre es requerido')
      end
    end
  end
end
```

### Ejecución

```bash
cd clientes-service
bundle exec rspec spec/domain/

# Salida esperada:
# Domain::Entities::Cliente
#   #initialize
#     with valid attributes
#       ✓ creates a cliente successfully
#     with invalid attributes
#       ✓ raises ArgumentError when nombre is empty
```

---

## Pruebas de Integración

### Objetivo

Validar la **comunicación entre microservicios** y el flujo completo de operaciones.

### Ubicación

```
clientes-service/spec/integration/
facturas-service/spec/integration/
```

### Arquitectura de Tests de Integración

```mermaid
graph TB
    subgraph "Integration Test Suite"
        TEST[RSpec Integration Test<br/>with WebMock]
    end

    subgraph "Facturas Service - Real"
        FCTL[FacturasController]
        FUC[Create Factura Use Case]
        FREPO[FacturaRepository]
        FDB[(SQLite DB)]
    end

    subgraph "External Services - Mocked"
        CMOCK[Clientes Service Mock<br/>WebMock Stub]
        AMOCK[Auditoría Service Mock<br/>WebMock Stub]
    end

    TEST -->|HTTP POST /facturas| FCTL
    FCTL --> FUC
    FUC -->|Validate Cliente| CMOCK
    FUC -->|Save| FREPO
    FREPO --> FDB
    FUC -->|Register Event| AMOCK

    CMOCK -.->|Returns| FUC
    AMOCK -.->|Returns| FUC
    FUC -->|Response| FCTL
    FCTL -->|HTTP Response| TEST

    style TEST fill:#4dabf7,stroke:#1971c2,color:#fff
    style FCTL fill:#51cf66,stroke:#2f9e44,color:#fff
    style CMOCK fill:#ff6b6b,stroke:#c92a2a,color:#fff
    style AMOCK fill:#ff6b6b,stroke:#c92a2a,color:#fff
    style FDB fill:#ffd43b,stroke:#f59f00,color:#000
```

### Flujo Completo: Crear Factura

```mermaid
sequenceDiagram
    participant Test as RSpec Test
    participant Facturas as Facturas Service
    participant ClientesMock as Clientes Service<br/>(Mocked)
    participant AuditMock as Auditoría Service<br/>(Mocked)
    participant DB as Database

    Test->>Facturas: POST /facturas<br/>{cliente_id: 1, monto: 1500000}

    Facturas->>ClientesMock: GET /clientes/1
    Note right of ClientesMock: WebMock Stub
    ClientesMock-->>Facturas: 200 OK<br/>{id: 1, nombre: "Empresa ABC"}

    Facturas->>DB: INSERT INTO facturas
    DB-->>Facturas: Factura created

    Facturas->>AuditMock: POST /auditoria<br/>{action: CREATE, entity: factura}
    Note right of AuditMock: WebMock Stub
    AuditMock-->>Facturas: 201 Created

    Facturas-->>Test: 201 Created<br/>{success: true, data: {...}}

    Test->>Test: Verify response
    Test->>Test: Assert stubs called
```

### Casos de Prueba: Cliente → Auditoría

```mermaid
graph LR
    subgraph "Test Cases"
        T1[✅ Happy Path<br/>Create Success]
        T2[✅ Error Handling<br/>Validation Fails]
        T3[✅ Resilience<br/>Audit Service Down]
        T4[✅ Read Operations<br/>GET Cliente]
        T5[✅ List Operations<br/>GET All Clientes]
    end

    T1 --> SUCCESS1[Cliente Created<br/>+<br/>Audit Registered]
    T2 --> ERROR1[422 Error<br/>+<br/>Error Logged]
    T3 --> RESILIENT1[Cliente Created<br/>+<br/>Audit Failed Silently]
    T4 --> SUCCESS2[Cliente Retrieved<br/>+<br/>Read Event Logged]
    T5 --> SUCCESS3[Clientes Listed<br/>+<br/>List Event Logged]

    style T1 fill:#51cf66,stroke:#2f9e44,color:#fff
    style T2 fill:#ff6b6b,stroke:#c92a2a,color:#fff
    style T3 fill:#ffd43b,stroke:#f59f00,color:#000
    style T4 fill:#51cf66,stroke:#2f9e44,color:#fff
    style T5 fill:#51cf66,stroke:#2f9e44,color:#fff
```

### Casos de Prueba: Factura → Cliente → Auditoría

```mermaid
graph TB
    subgraph "Integration Test Cases"
        direction TB
        T1[Complete Flow Test]
        T2[Cliente Not Found]
        T3[Invalid Business Rules]
        T4[Date Range Filtering]
        T5[Service Failures]
        T6[Circuit Breaker]
    end

    T1 --> R1[✅ Validate Cliente<br/>✅ Create Factura<br/>✅ Register Audit]
    T2 --> R2[❌ 404 from Clientes<br/>❌ Factura Rejected<br/>✅ Error Logged]
    T3 --> R3[❌ Monto ≤ 0<br/>❌ Invalid Date<br/>✅ Error Logged]
    T4 --> R4[✅ Filter by Date Range<br/>✅ Return Matching<br/>✅ Audit Query]
    T5 --> R5[⚠️ Clientes Timeout<br/>❌ Factura Failed<br/>✅ Error Logged]
    T6 --> R6[✅ Factura Created<br/>⚠️ Audit Failed<br/>✅ Operation Continues]

    style T1 fill:#51cf66,stroke:#2f9e44,color:#fff
    style T2 fill:#ff6b6b,stroke:#c92a2a,color:#fff
    style T3 fill:#ff6b6b,stroke:#c92a2a,color:#fff
    style T4 fill:#4dabf7,stroke:#1971c2,color:#fff
    style T5 fill:#ffd43b,stroke:#f59f00,color:#000
    style T6 fill:#ffd43b,stroke:#f59f00,color:#000
```

### Ejemplo: Test de Flujo Completo

```ruby
# spec/integration/facturas_clientes_auditoria_integration_spec.rb
RSpec.describe 'Integration: Facturas → Clientes → Auditoría' do
  let(:clientes_url) { ENV['CLIENTES_SERVICE_URL'] }
  let(:auditoria_url) { ENV['AUDITORIA_SERVICE_URL'] }

  describe 'POST /facturas - Complete flow' do
    it 'validates cliente, creates factura, and registers audit events' do
      # Step 1: Mock Clientes service - validate cliente exists
      cliente_stub = stub_request(:get, "#{clientes_url}/clientes/1")
        .to_return(
          status: 200,
          body: {
            success: true,
            data: {
              id: 1,
              nombre: 'Empresa ABC S.A.',
              identificacion: '900123456'
            }
          }.to_json
        )

      # Step 2: Mock Auditoría service - register event
      audit_stub = stub_request(:post, "#{auditoria_url}/auditoria")
        .with(
          body: hash_including(
            entity_type: 'factura',
            action: 'CREATE',
            status: 'SUCCESS'
          )
        )
        .to_return(status: 201, body: { success: true }.to_json)

      # Step 3: Create factura
      post '/facturas', {
        cliente_id: 1,
        fecha_emision: Date.today.to_s,
        monto: 1500000
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }

      # Verify response
      expect(last_response.status).to eq(201)

      # Verify service interactions
      expect(cliente_stub).to have_been_requested.once
      expect(audit_stub).to have_been_requested.once
    end
  end
end
```

---

**Versión:** 1.0
**Última actualización:** Enero 2025
**Autor:** Justin Hernandez
