# 🧪 Guía de Testing - FactuMarket

> Testing automatizado con **RSpec**, cobertura con **SimpleCov** y mocks con **WebMock**.

---

## 📋 Tabla de Contenidos

- [Ejecutar Tests](#-ejecutar-tests)
- [Cobertura de Código](#-cobertura-de-código)
- [Estructura de Tests](#-estructura-de-tests)
- [Mejores Prácticas](#-mejores-prácticas)
- [Troubleshooting](#-troubleshooting)

---

## ▶️ Ejecutar Tests

### Comandos Rake (Recomendado)

| Comando | Descripción |
|---------|-------------|
| `rake test` | Todos los tests de todos los servicios |
| `rake test_unit` | Solo tests unitarios (Domain + Application + Infrastructure) |
| `rake coverage` | Generar reportes de cobertura de todos los servicios |
| `rake coverage_summary` | Ver resumen de cobertura en terminal |
| `rake clean_coverage` | Eliminar reportes de cobertura |

### Por Servicio Individual

```bash
# Auditoría Service
rake auditoria:test          # Todos los tests
rake auditoria:test_unit     # Solo unitarios
rake auditoria:coverage      # Cobertura

# Clientes Service
rake clientes:test
rake clientes:test_unit
rake clientes:coverage

# Facturas Service
rake facturas:test
rake facturas:test_unit
rake facturas:coverage
```

### RSpec Directo (Granular)

```bash
cd clientes-service

# Por capa
bundle exec rspec spec/domain          # Domain layer
bundle exec rspec spec/application     # Application layer
bundle exec rspec spec/infrastructure  # Infrastructure layer
bundle exec rspec spec/integration     # Integration tests

# Archivo específico
bundle exec rspec spec/domain/entities/cliente_spec.rb

# Test específico por línea
bundle exec rspec spec/domain/entities/cliente_spec.rb:25
```

---

## 📊 Cobertura de Código

### Generar Reportes

```bash
# Todos los servicios
rake coverage

# Ver resumen
rake coverage_summary
```

**Output esperado:**
```
auditoria-service            92.45% (123/133 líneas)
clientes-service             88.67% (98/110 líneas)
facturas-service             90.12% (104/115 líneas)
```

**Reportes HTML:**
- `auditoria-service/coverage/index.html`
- `clientes-service/coverage/index.html`
- `facturas-service/coverage/index.html`

### Objetivos de Cobertura

| Nivel | Porcentaje |
|-------|------------|
| **Mínimo requerido** | 80% |
| **Objetivo ideal** | 90%+ |

SimpleCov mostrará un **warning** si la cobertura es menor al 80%.

---

## 📁 Estructura de Tests

```
servicio/spec/
├── spec_helper.rb                # Configuración RSpec + SimpleCov
├── integration_spec_helper.rb    # Helper para tests de integración
├── domain/
│   └── entities/                # Tests de entidades (lógica pura)
├── application/
│   └── use_cases/               # Tests de casos de uso
├── infrastructure/
│   └── persistence/             # Tests de repositorios
└── integration/                 # Tests end-to-end
```

### Distribución por Capa

| Capa | Foco | % de Tests | Dependencias |
|------|------|------------|--------------|
| **Domain** | Validaciones, lógica de negocio | ~30% | Ninguna (tests puros) |
| **Application** | Casos de uso, orquestación | ~40% | Mocks de repositorios |
| **Infrastructure** | Repositorios, adaptadores | ~20% | Mocks de DB (ActiveRecord/Mongo) |
| **Integration** | End-to-end, comunicación entre servicios | ~10% | WebMock para HTTP |

---

## 💡 Mejores Prácticas

### 1. Nomenclatura Consistente

```ruby
RSpec.describe Domain::Entities::Cliente do
  describe '#initialize' do
    context 'with valid attributes' do
      it 'creates a cliente successfully' do
        # ...
      end
    end

    context 'with invalid nombre' do
      it 'raises ArgumentError' do
        expect { described_class.new(nombre: '') }.to raise_error(ArgumentError)
      end
    end
  end
end
```

### 2. Mocks y Doubles

```ruby
# Double para repositorios
let(:repository) { instance_double(Domain::Repositories::ClienteRepository) }

# Stubbing
allow(repository).to receive(:find_by_id).and_return(cliente)

# Expectation
expect(repository).to receive(:save).with(cliente).and_return(true)
```

### 3. WebMock para Servicios Externos

```ruby
# Mockear llamadas HTTP entre servicios
stub_request(:post, "http://localhost:4003/auditoria")
  .with(body: hash_including(action: "CREATE"))
  .to_return(status: 201, body: { success: true }.to_json)
```

### 4. Database Cleaner

```ruby
# En spec_helper.rb
config.around(:each) do |example|
  DatabaseCleaner.cleaning do
    example.run
  end
end
```

---

## 📈 Estado Actual

| Servicio | Tests Unitarios | Tests Integración | Total | Cobertura |
|----------|-----------------|-------------------|-------|-----------|
| **Auditoría** | 35 | 13 | 48 | ~92% ✅ |
| **Clientes** | 28 | 8+ | 36+ | ~88% ✅ |
| **Facturas** | 27 | 9+ | 36+ | ~90% ✅ |

---

## 🐛 Troubleshooting

### Problema: SimpleCov no genera reportes

```bash
# Verificar instalación
bundle install

# Asegurarse que spec_helper.rb carga SimpleCov PRIMERO
# (antes de require de la aplicación)
```

### Problema: Tests fallan por base de datos

```bash
# Verificar que las bases de datos de test existen
cd clientes-service
bundle exec rake db:test:prepare

cd ../facturas-service
bundle exec rake db:test:prepare
```

### Problema: WebMock bloquea conexiones localhost

```bash
# En spec_helper.rb
WebMock.disable_net_connect!(allow_localhost: true)
```

### Problema: MongoDB no conecta en tests

```bash
# Verificar que MongoDB esté corriendo
docker-compose up -d mongodb

# O iniciarlo localmente
mongod --dbpath ./data/db
```

---

## 📖 Guías Rápidas

### Escribir Test de Dominio

```ruby
# spec/domain/entities/cliente_spec.rb
require 'spec_helper'

RSpec.describe Domain::Entities::Cliente do
  describe '#valid?' do
    it 'returns true with valid attributes' do
      cliente = described_class.new(
        nombre: 'Test S.A.',
        identificacion: '900123456',
        correo: 'test@example.com'
      )
      expect(cliente).to be_valid
    end
  end
end
```

### Escribir Test de Use Case

```ruby
# spec/application/use_cases/create_cliente_spec.rb
require 'spec_helper'

RSpec.describe Application::UseCases::CreateCliente do
  let(:repository) { instance_double(Domain::Repositories::ClienteRepository) }
  let(:use_case) { described_class.new(cliente_repository: repository) }

  it 'creates cliente successfully' do
    allow(repository).to receive(:save).and_return(cliente)

    result = use_case.execute(nombre: 'Test', identificacion: '123')

    expect(result.nombre).to eq('Test')
  end
end
```

### Escribir Test de Integración

```ruby
# spec/integration/clientes_api_spec.rb
require 'integration_spec_helper'

RSpec.describe 'Clientes API', type: :request do
  it 'creates a new cliente' do
    data = {
      nombre: 'Test S.A.',
      identificacion: '900123456',
      correo: 'test@example.com'
    }

    post '/clientes', data.to_json, { 'CONTENT_TYPE' => 'application/json' }

    expect(last_response.status).to eq(201)
    json = JSON.parse(last_response.body)
    expect(json['success']).to be true
    expect(json['data']['nombre']).to eq('Test S.A.')
  end
end
```

---

## 🔧 Configuración de SimpleCov

```ruby
# spec_helper.rb (en cada servicio)
require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/db/'

  add_group 'Domain', 'app/domain'
  add_group 'Application', 'app/application'
  add_group 'Infrastructure', 'app/infrastructure'
  add_group 'Controllers', 'app/controllers'

  track_files 'app/**/*.rb'
  minimum_coverage 80
end
```

---

## 🚀 Comandos Útiles

```bash
# Ver tareas disponibles
rake help

# Tests + cobertura en un comando
rake test && rake coverage_summary

# Tests con output detallado
cd clientes-service
bundle exec rspec --format documentation --color

# Limpiar y regenerar todo
rake clean_coverage && rake test && rake coverage
```

---

## 📚 Referencias

- [RSpec Documentation](https://rspec.info/)
- [SimpleCov GitHub](https://github.com/simplecov-ruby/simplecov)
- [WebMock Documentation](https://github.com/bblimke/webmock)
- [Database Cleaner](https://github.com/DatabaseCleaner/database_cleaner)

---

**📌 Nota:** Para ver ejemplos completos de tests, explorar las carpetas `spec/` de cada servicio.
