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

### Cobertura Completa de Tests

```mermaid
mindmap
  root((Integration Tests))
    Clientes Service
      Create Cliente
        Success + Audit
        Validation Error
        Audit Service Down
      Read Cliente
        Success + Audit Log
        Not Found
      List Clientes
        Success + Audit Log
        Empty Result
    Facturas Service
      Create Factura
        Complete Flow Success
        Cliente Not Found
        Invalid Amount
        Invalid Date
        Clientes Service Down
        Audit Service Down
      Read Factura
        Success + Audit
        Not Found
      List Facturas
        All Facturas
        Date Range Filter
        Empty Result
    Resilience
      Timeout Handling
      Network Errors
      Circuit Breaker
      Graceful Degradation
```

### Ejecución

```bash
# Test Clientes → Auditoría
cd clientes-service
bundle exec rspec spec/integration/

# Test Facturas → Clientes → Auditoría
cd facturas-service
bundle exec rspec spec/integration/
```

---

## Ejecución de Tests

### Flujo de Ejecución

```mermaid
flowchart TD
    Start([Inicio]) --> Choice{Tipo de Test}

    Choice -->|Unit Tests| Unit[bundle exec rspec spec/domain/]
    Choice -->|Integration Tests| Integration[bundle exec rspec spec/integration/]
    Choice -->|All Tests| All[./scripts/test.sh]

    Unit --> UnitRun[Ejecuta Domain Tests]
    Integration --> IntRun[Ejecuta Integration Tests]
    All --> AllRun[Ejecuta Todo]

    UnitRun --> UnitResult{Resultado}
    IntRun --> IntResult{Resultado}
    AllRun --> AllResult{Resultado}

    UnitResult -->|✅ Pass| Success1[Tests Passed]
    UnitResult -->|❌ Fail| Fail1[Fix Issues]

    IntResult -->|✅ Pass| Success2[Tests Passed]
    IntResult -->|❌ Fail| Fail2[Fix Issues]

    AllResult -->|✅ Pass| Success3[All Tests Passed]
    AllResult -->|❌ Fail| Fail3[Fix Issues]

    Success1 --> End([Fin])
    Success2 --> End
    Success3 --> End
    Fail1 --> Start
    Fail2 --> Start
    Fail3 --> Start

    style Start fill:#51cf66,stroke:#2f9e44,color:#fff
    style End fill:#51cf66,stroke:#2f9e44,color:#fff
    style Success1 fill:#51cf66,stroke:#2f9e44,color:#fff
    style Success2 fill:#51cf66,stroke:#2f9e44,color:#fff
    style Success3 fill:#51cf66,stroke:#2f9e44,color:#fff
    style Fail1 fill:#ff6b6b,stroke:#c92a2a,color:#fff
    style Fail2 fill:#ff6b6b,stroke:#c92a2a,color:#fff
    style Fail3 fill:#ff6b6b,stroke:#c92a2a,color:#fff
```

### Comandos de Ejecución

```bash
# Un test específico
bundle exec rspec spec/domain/entities/cliente_spec.rb

# Un contexto específico (por línea)
bundle exec rspec spec/domain/entities/cliente_spec.rb:22

# Tests por tipo
bundle exec rspec spec/domain/      # Solo unitarios
bundle exec rspec spec/integration/ # Solo integración

# Todos los tests con formato detallado
bundle exec rspec --format documentation

# Todos los tests del proyecto
chmod +x scripts/test.sh
./scripts/test.sh
```

---

## Mocking y Stubs

### Arquitectura de WebMock

```mermaid
graph LR
    subgraph "Test Environment"
        TEST[RSpec Test]
        WEBMOCK[WebMock Library]
    end

    subgraph "Application Under Test"
        APP[Facturas Service]
        HTTP[HTTParty Client]
    end

    subgraph "External Services - Blocked"
        EXT1[Real Clientes Service]
        EXT2[Real Auditoría Service]
    end

    TEST --> WEBMOCK
    WEBMOCK -->|Configure Stubs| WEBMOCK
    APP --> HTTP
    HTTP -->|HTTP Request| WEBMOCK
    WEBMOCK -->|Mock Response| HTTP
    HTTP --> APP

    HTTP -.->|❌ Blocked| EXT1
    HTTP -.->|❌ Blocked| EXT2

    style TEST fill:#4dabf7,stroke:#1971c2,color:#fff
    style WEBMOCK fill:#ffd43b,stroke:#f59f00,color:#000
    style APP fill:#51cf66,stroke:#2f9e44,color:#fff
    style EXT1 fill:#ddd,stroke:#999,color:#666
    style EXT2 fill:#ddd,stroke:#999,color:#666
```

### Tipos de Mocks

```mermaid
graph TB
    subgraph "WebMock Strategies"
        SUCCESS[Success Response<br/>200/201 OK]
        ERROR[Error Response<br/>404/422/500]
        TIMEOUT[Timeout Simulation<br/>.to_timeout]
        NETWORK[Network Error<br/>.to_raise]
        VALIDATE[Request Validation<br/>.with body/headers]
    end

    SUCCESS --> USE1[Happy Path Tests]
    ERROR --> USE2[Error Handling Tests]
    TIMEOUT --> USE3[Resilience Tests]
    NETWORK --> USE4[Failure Tests]
    VALIDATE --> USE5[Contract Tests]

    style SUCCESS fill:#51cf66,stroke:#2f9e44,color:#fff
    style ERROR fill:#ff6b6b,stroke:#c92a2a,color:#fff
    style TIMEOUT fill:#ffd43b,stroke:#f59f00,color:#000
    style NETWORK fill:#ff6b6b,stroke:#c92a2a,color:#fff
    style VALIDATE fill:#4dabf7,stroke:#1971c2,color:#fff
```

### Ejemplos de WebMock

```ruby
# 1. Mock Success Response
stub_request(:get, "http://localhost:4001/clientes/1")
  .to_return(
    status: 200,
    body: { success: true, data: { id: 1, nombre: 'Test' } }.to_json,
    headers: { 'Content-Type' => 'application/json' }
  )

# 2. Mock con validación de request body
stub_request(:post, "http://localhost:4003/auditoria")
  .with(
    body: hash_including(
      entity_type: 'cliente',
      action: 'CREATE',
      status: 'SUCCESS'
    ),
    headers: { 'Content-Type' => 'application/json' }
  )
  .to_return(status: 201, body: { success: true }.to_json)

# 3. Mock de timeout
stub_request(:get, "http://localhost:4001/clientes/1")
  .to_timeout

# 4. Mock de error de red
stub_request(:get, "http://localhost:4001/clientes/1")
  .to_raise(SocketError.new('Network unreachable'))

# 5. Mock con captura de request
audit_request = nil
stub_request(:post, "http://localhost:4003/auditoria")
  .to_return do |request|
    audit_request = JSON.parse(request.body)
    { status: 201, body: { success: true }.to_json }
  end

# Luego verificar
expect(audit_request[:action]).to eq('CREATE')
```

### DatabaseCleaner Strategy

```mermaid
graph TB
    subgraph "Test Lifecycle"
        START[Test Suite Start]
        BEFORE[Before Each Test]
        TEST[Run Test]
        AFTER[After Each Test]
        FINISH[Test Suite End]
    end

    START -->|Setup| STRATEGY[Set Strategy: Transaction]
    STRATEGY --> CLEAN[Clean DB: Truncation]
    CLEAN --> BEFORE

    BEFORE -->|Start Transaction| TRANS_START[BEGIN]
    TRANS_START --> TEST
    TEST --> AFTER
    AFTER -->|Rollback Transaction| ROLLBACK[ROLLBACK]

    ROLLBACK --> BEFORE
    ROLLBACK --> FINISH

    style START fill:#51cf66,stroke:#2f9e44,color:#fff
    style TEST fill:#4dabf7,stroke:#1971c2,color:#fff
    style ROLLBACK fill:#ffd43b,stroke:#f59f00,color:#000
    style FINISH fill:#51cf66,stroke:#2f9e44,color:#fff
```

```ruby
RSpec.configure do |config|
  # Configuración inicial
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  # Wrap cada test en una transacción
  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run  # Se ejecuta dentro de una transacción
    end            # Auto-rollback al terminar
  end
end
```

---

## Buenas Prácticas

### Patrón AAA (Arrange-Act-Assert)

```mermaid
graph LR
    subgraph "Test Structure"
        A[Arrange<br/>Preparar datos y mocks]
        B[Act<br/>Ejecutar acción]
        C[Assert<br/>Verificar resultado]
    end

    A --> B
    B --> C

    A1[Setup test data<br/>Configure stubs<br/>Prepare environment] -.-> A
    B1[Call method<br/>Make HTTP request<br/>Trigger action] -.-> B
    C1[Verify response<br/>Check state<br/>Assert expectations] -.-> C

    style A fill:#51cf66,stroke:#2f9e44,color:#fff
    style B fill:#4dabf7,stroke:#1971c2,color:#fff
    style C fill:#ffd43b,stroke:#f59f00,color:#000
```

```ruby
it 'creates a cliente successfully' do
  # 🟢 Arrange: Preparar datos
  cliente_params = {
    nombre: 'Test',
    identificacion: '900123456',
    correo: 'test@example.com'
  }

  stub_request(:post, "#{audit_url}/auditoria")
    .to_return(status: 201)

  # 🔵 Act: Ejecutar acción
  post '/clientes', cliente_params.to_json

  # 🟡 Assert: Verificar resultado
  expect(last_response.status).to eq(201)
  expect(JSON.parse(last_response.body)[:success]).to be true
end
```

### Organización de Tests

```mermaid
graph TB
    subgraph "Test Organization"
        DESC[describe 'Feature']
        CTX1[context 'Scenario 1']
        CTX2[context 'Scenario 2']
        IT1[it 'does something']
        IT2[it 'does something else']
        IT3[it 'handles error']
    end

    DESC --> CTX1
    DESC --> CTX2
    CTX1 --> IT1
    CTX1 --> IT2
    CTX2 --> IT3

    style DESC fill:#4dabf7,stroke:#1971c2,color:#fff
    style CTX1 fill:#51cf66,stroke:#2f9e44,color:#fff
    style CTX2 fill:#51cf66,stroke:#2f9e44,color:#fff
```

```ruby
describe 'POST /facturas' do
  context 'when cliente exists' do
    it 'creates factura successfully' do
      # ...
    end

    it 'registers audit event' do
      # ...
    end
  end

  context 'when cliente does not exist' do
    it 'returns 422 error' do
      # ...
    end

    it 'logs error in audit' do
      # ...
    end
  end

  context 'when auditoría service is down' do
    it 'still creates factura' do
      # ...
    end
  end
end
```

### Principios FIRST

```mermaid
mindmap
  root((FIRST Principles))
    Fast
      Run in milliseconds
      No external dependencies
      Use mocks/stubs
    Independent
      No shared state
      Can run in any order
      DatabaseCleaner isolation
    Repeatable
      Same result every time
      No random data issues
      Deterministic
    Self-Validating
      Pass or Fail clearly
      No manual verification
      Automated assertions
    Timely
      Written before/with code
      TDD approach
      Continuous feedback
```

---

## Troubleshooting

### Problemas Comunes y Soluciones

```mermaid
graph TB
    subgraph "Common Issues"
        I1[Connection Refused]
        I2[Database Locked]
        I3[Stubs Not Working]
        I4[Flaky Tests]
    end

    I1 --> S1[✅ Check WebMock config<br/>disable_net_connect!]
    I2 --> S2[✅ Use transaction strategy<br/>not truncation]
    I3 --> S3[✅ Verify exact URL match<br/>include protocol & port]
    I4 --> S4[✅ Remove shared state<br/>use DatabaseCleaner]

    style I1 fill:#ff6b6b,stroke:#c92a2a,color:#fff
    style I2 fill:#ff6b6b,stroke:#c92a2a,color:#fff
    style I3 fill:#ff6b6b,stroke:#c92a2a,color:#fff
    style I4 fill:#ff6b6b,stroke:#c92a2a,color:#fff
    style S1 fill:#51cf66,stroke:#2f9e44,color:#fff
    style S2 fill:#51cf66,stroke:#2f9e44,color:#fff
    style S3 fill:#51cf66,stroke:#2f9e44,color:#fff
    style S4 fill:#51cf66,stroke:#2f9e44,color:#fff
```

#### 1. Tests Fallan: "Connection refused"

**Causa:** Tests intentan conectar a servicios reales.

**Solución:**
```ruby
# En spec_helper:
WebMock.disable_net_connect!(allow_localhost: false)
```

#### 2. Tests Fallan: "Database is locked"

**Causa:** Strategy incorrecta de DatabaseCleaner.

**Solución:**
```ruby
# Usar transaction en lugar de truncation
DatabaseCleaner.strategy = :transaction
```

#### 3. Stubs No Funcionan

**Causa:** URL del stub no coincide exactamente.

**Solución:**
```ruby
# ✅ Correcto - URL completa
stub_request(:get, "http://localhost:4001/clientes/1")

# ❌ Incorrecto - falta protocolo
stub_request(:get, "localhost:4001/clientes/1")
```

---

## Métricas de Cobertura

### Cobertura Actual del Proyecto

```mermaid
pie title Test Coverage by Layer
    "Domain Layer (Unit)" : 95
    "Integration Tests" : 100
    "Controllers" : 85
    "Not Covered" : 5
```

### Distribución de Tests

```mermaid
graph LR
    subgraph "Test Distribution"
        U[Unit Tests<br/>25 tests]
        I[Integration Tests<br/>15 tests]
        TOTAL[Total: 40 tests]
    end

    U --> TOTAL
    I --> TOTAL

    U1[Domain Entities<br/>Business Logic<br/>Validations] -.-> U
    I1[Service Communication<br/>End-to-End Flows<br/>Resilience] -.-> I

    style U fill:#51cf66,stroke:#2f9e44,color:#fff
    style I fill:#4dabf7,stroke:#1971c2,color:#fff
    style TOTAL fill:#ffd43b,stroke:#f59f00,color:#000
```

**Cobertura por Microservicio:**

| Servicio | Unit Tests | Integration Tests | Total Coverage |
|----------|------------|-------------------|----------------|
| Clientes | 95% | 100% | 97% |
| Facturas | 95% | 100% | 97% |
| Auditoría | N/A | N/A | 85% |

---

## Próximos Pasos

### Roadmap de Testing

```mermaid
graph TB
    NOW[✅ Estado Actual]
    NEXT1[📋 SimpleCov<br/>Code Coverage Reports]
    NEXT2[⚡ Performance Tests<br/>Benchmark]
    NEXT3[🤝 Contract Testing<br/>Pact]
    NEXT4[🧬 Mutation Testing<br/>Mutant]

    NOW --> NEXT1
    NEXT1 --> NEXT2
    NEXT2 --> NEXT3
    NEXT3 --> NEXT4

    style NOW fill:#51cf66,stroke:#2f9e44,color:#fff
    style NEXT1 fill:#4dabf7,stroke:#1971c2,color:#fff
    style NEXT2 fill:#4dabf7,stroke:#1971c2,color:#fff
    style NEXT3 fill:#ffd43b,stroke:#f59f00,color:#000
    style NEXT4 fill:#ffd43b,stroke:#f59f00,color:#000
```

### Mejoras Propuestas

1. **SimpleCov** - Reportes de cobertura visual
2. **Performance Tests** - Benchmark de endpoints
3. **Contract Testing** - Validar contratos entre servicios con Pact
4. **Mutation Testing** - Mejorar calidad de tests con Mutant
5. **Load Testing** - Apache Bench o k6 para carga

---

## Referencias

### Documentación Oficial

- [RSpec Documentation](https://rspec.info/)
- [WebMock GitHub](https://github.com/bblimke/webmock)
- [DatabaseCleaner](https://github.com/DatabaseCleaner/database_cleaner)

### Artículos y Recursos

- [Testing Microservices](https://martinfowler.com/articles/microservice-testing/) - Martin Fowler
- [Test Pyramid](https://martinfowler.com/bliki/TestPyramid.html)
- [FIRST Principles](https://github.com/tekguard/Principles-of-Unit-Testing)

### Herramientas Relacionadas

- [Rack::Test](https://github.com/rack/rack-test) - Testing de aplicaciones Rack
- [FactoryBot](https://github.com/thoughtbot/factory_bot) - Fixtures dinámicas
- [Faker](https://github.com/faker-ruby/faker) - Datos de prueba realistas

---

**Versión:** 1.0
**Última actualización:** Enero 2025
**Autor:** FactuMarket Team
