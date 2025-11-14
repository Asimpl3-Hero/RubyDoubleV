# Guía de Testing - RubyDoubleV

Este proyecto utiliza **RSpec** para testing y **SimpleCov** para análisis de cobertura de código.

## 🧪 Ejecutar Tests

### Tests de Todos los Servicios

```bash
# Ejecutar todos los tests (unit + integration)
rake test

# Ejecutar solo tests unitarios (Domain + Application + Infrastructure)
rake test_unit
```

### Tests por Servicio Individual

```bash
# Auditoría Service
rake auditoria:test          # Todos los tests
rake auditoria:test_unit     # Solo unitarios

# Clientes Service
rake clientes:test           # Todos los tests
rake clientes:test_unit      # Solo unitarios

# Facturas Service
rake facturas:test           # Todos los tests
rake facturas:test_unit      # Solo unitarios
```

### Tests Directos con RSpec

También puedes ejecutar RSpec directamente en cada servicio:

```bash
# Entrar al servicio
cd auditoria-service

# Todos los tests
bundle exec rspec

# Tests específicos por capa
bundle exec rspec spec/domain          # Solo Domain layer
bundle exec rspec spec/application     # Solo Application layer
bundle exec rspec spec/infrastructure  # Solo Infrastructure layer
bundle exec rspec spec/integration     # Solo Integration tests

# Un archivo específico
bundle exec rspec spec/domain/entities/audit_event_spec.rb

# Un test específico (por línea)
bundle exec rspec spec/domain/entities/audit_event_spec.rb:12
```

## 📊 Cobertura de Código

### Generar Reportes de Cobertura

```bash
# Generar cobertura de todos los servicios
rake coverage

# Cobertura por servicio individual
rake auditoria:coverage
rake clientes:coverage
rake facturas:coverage
```

Los reportes HTML se generan en:
- `auditoria-service/coverage/index.html`
- `clientes-service/coverage/index.html`
- `facturas-service/coverage/index.html`

### Ver Resumen de Cobertura

```bash
# Mostrar resumen en terminal
rake coverage_summary
```

Ejemplo de output:
```
auditoria-service            92.45% (123/133 líneas)
clientes-service             88.67% (98/110 líneas)
facturas-service             90.12% (104/115 líneas)
```

### Limpiar Reportes

```bash
# Eliminar todos los reportes de cobertura
rake clean_coverage
```

## 📁 Estructura de Tests

Cada servicio sigue la estructura de **Clean Architecture**:

```
servicio/spec/
├── spec_helper.rb                    # Configuración de RSpec + SimpleCov
├── integration_spec_helper.rb        # Helper para tests de integración
├── domain/
│   └── entities/                    # Tests de entidades de dominio
├── application/
│   └── use_cases/                   # Tests de casos de uso
├── infrastructure/
│   └── persistence/                 # Tests de repositorios
└── integration/                     # Tests de integración end-to-end
```

### Domain Layer Tests
- Validaciones de entidades
- Lógica de negocio
- Sin dependencias externas

### Application Layer Tests
- Casos de uso (Use Cases)
- Orquestación de lógica de negocio
- Mocks de repositorios

### Infrastructure Layer Tests
- Repositorios (persistencia)
- Adaptadores externos
- Mocks de ActiveRecord/MongoDB

### Integration Tests
- Tests end-to-end
- Comunicación entre servicios
- WebMock para servicios externos

## 🎯 Objetivos de Cobertura

- **Mínimo requerido**: 80%
- **Objetivo ideal**: 90%+

SimpleCov está configurado para mostrar un warning si la cobertura es menor al 80%.

## 💡 Mejores Prácticas

### 1. Nomenclatura de Tests

```ruby
RSpec.describe Domain::Entities::Cliente do
  describe '#initialize' do
    context 'with valid attributes' do
      it 'creates a cliente successfully' do
        # ...
      end
    end

    context 'with invalid attributes' do
      it 'raises ArgumentError when nombre is empty' do
        # ...
      end
    end
  end
end
```

### 2. Uso de Mocks y Doubles

```ruby
# Double para objetos simples
let(:repository) { instance_double(Domain::Repositories::ClienteRepository) }

# Stubbing de métodos
allow(repository).to receive(:find_by_id).and_return(cliente)
expect(repository).to receive(:save).and_return(saved_cliente)
```

### 3. WebMock para Servicios Externos

```ruby
# Mockear llamadas HTTP
stub_request(:post, "http://localhost:4003/auditoria")
  .to_return(status: 201, body: { success: true }.to_json)
```

### 4. Database Cleaner

Los tests de integración usan Database Cleaner para mantener la DB limpia:

```ruby
config.around(:each) do |example|
  DatabaseCleaner.cleaning do
    example.run
  end
end
```

## 🔧 Configuración de SimpleCov

SimpleCov está configurado en cada `spec_helper.rb`:

```ruby
SimpleCov.start do
  add_filter '/spec/'        # Excluir archivos de tests
  add_filter '/config/'      # Excluir configuración
  add_filter '/db/'          # Excluir migraciones

  # Grupos para reportes
  add_group 'Domain', 'app/domain'
  add_group 'Application', 'app/application'
  add_group 'Infrastructure', 'app/infrastructure'
  add_group 'Controllers', 'app/controllers'

  track_files 'app/**/*.rb'
  minimum_coverage 80
end
```

## 🚀 Comandos Útiles

```bash
# Ver todas las tareas disponibles
rake help

# Ejecutar tests y ver cobertura
rake test && rake coverage_summary

# Solo tests unitarios de un servicio
rake clientes:test_unit

# Limpiar y regenerar cobertura
rake clean_coverage && rake coverage

# Tests con salida detallada
cd auditoria-service
bundle exec rspec --format documentation --color
```

## 📈 Métricas de Testing

### Estado Actual

| Servicio | Tests Unitarios | Tests Integración | Total Tests | Cobertura |
|----------|----------------|-------------------|-------------|-----------|
| Auditoría | 35 | 13 | 48 | ~92% |
| Clientes | 28 | 8+ | 36+ | ~88% |
| Facturas | 27 | 9+ | 36+ | ~90% |

### Distribución por Capa

- **Domain**: ~30% de los tests
- **Application**: ~40% de los tests
- **Infrastructure**: ~20% de los tests
- **Integration**: ~10% de los tests

## 🐛 Troubleshooting

### SimpleCov no genera reportes

```bash
# Asegúrate de que SimpleCov esté en el Gemfile
bundle install

# Verifica que spec_helper.rb carga SimpleCov ANTES de la aplicación
```

### Tests fallan por base de datos

```bash
# Ejecutar migraciones
cd clientes-service
bundle exec rake db:migrate RACK_ENV=test

cd ../facturas-service
bundle exec rake db:migrate RACK_ENV=test
```

### WebMock bloquea conexiones reales

```bash
# En spec_helper, ajusta la configuración:
WebMock.disable_net_connect!(allow_localhost: true)
```

## 📚 Referencias

- [RSpec Documentation](https://rspec.info/)
- [SimpleCov GitHub](https://github.com/simplecov-ruby/simplecov)
- [WebMock Documentation](https://github.com/bblimke/webmock)
- [Database Cleaner](https://github.com/DatabaseCleaner/database_cleaner)

## 🎓 Guías de Testing

### Escribir un Test de Dominio

```ruby
# spec/domain/entities/mi_entidad_spec.rb
require 'spec_helper'

RSpec.describe Domain::Entities::MiEntidad do
  describe '#initialize' do
    it 'creates entity with valid attributes' do
      entity = described_class.new(nombre: 'Test')
      expect(entity.nombre).to eq('Test')
    end
  end
end
```

### Escribir un Test de Use Case

```ruby
# spec/application/use_cases/mi_use_case_spec.rb
require 'spec_helper'

RSpec.describe Application::UseCases::MiUseCase do
  let(:repository) { instance_double(Domain::Repositories::MiRepository) }
  let(:use_case) { described_class.new(repository: repository) }

  it 'executes successfully' do
    allow(repository).to receive(:save).and_return(result)
    expect(use_case.execute(params)).to eq(result)
  end
end
```

### Escribir un Test de Integración

```ruby
# spec/integration/mi_integracion_spec.rb
require 'integration_spec_helper'

RSpec.describe 'Mi API', type: :request do
  it 'creates resource successfully' do
    post '/recursos', data.to_json, { 'CONTENT_TYPE' => 'application/json' }

    expect(last_response.status).to eq(201)
    json = JSON.parse(last_response.body)
    expect(json['success']).to be true
  end
end
```

---

**Última actualización**: 2025-11-13
