# Audit Consumer Worker

## 📋 Descripción

Este directorio contiene el **worker de consumo de eventos de auditoría** que procesa mensajes de forma asíncrona desde RabbitMQ y los persiste en MongoDB.

## 🎯 Propósito

El `audit_consumer.rb` es un **proceso background** que:

1. Escucha mensajes de la cola `audit_events` en RabbitMQ
2. Deserializa los eventos de auditoría (JSON)
3. Persiste cada evento en MongoDB usando el caso de uso `CreateAuditEvent`
4. Confirma (ACK) o rechaza (NACK) el mensaje según el resultado

## 🔄 Flujo de Comunicación Asíncrona

### Arquitectura General

```mermaid
graph LR
    A[Clientes Service] -->|Publica eventos| C[RabbitMQ<br/>Message Broker]
    B[Facturas Service] -->|Publica eventos| C
    C -->|Cola: audit_events| D[Auditoria Consumer<br/>este worker]
    D -->|Persiste| E[(MongoDB<br/>auditoria_db)]

    style C fill:#ff9800,stroke:#e65100,stroke-width:3px,color:#fff
    style D fill:#4caf50,stroke:#2e7d32,stroke-width:2px,color:#fff
    style E fill:#2196f3,stroke:#1565c0,stroke-width:2px,color:#fff
```

### Diagrama de Secuencia - Flujo Asíncrono

```mermaid
sequenceDiagram
    actor User
    participant CS as Clientes Service
    participant AP as AuditPublisher
    participant RMQ as RabbitMQ
    participant AC as Audit Consumer
    participant DB as MongoDB

    User->>CS: POST /clientes
    activate CS
    CS->>CS: Crear cliente (50ms)
    CS->>AP: publish(event)
    activate AP
    AP->>RMQ: Enviar mensaje a cola
    RMQ-->>AP: OK
    deactivate AP
    Note over CS,AP: < 5ms (no bloqueante)
    CS-->>User: 201 Created ✓
    deactivate CS
    Note over User,CS: Usuario recibe respuesta<br/>TOTAL: ~55ms

    Note over RMQ,AC: Proceso asíncrono en background

    RMQ->>AC: Entregar mensaje
    activate AC
    AC->>AC: Deserializar JSON
    AC->>DB: Guardar evento
    DB-->>AC: OK
    AC->>RMQ: ACK (confirmar)
    deactivate AC
    Note over RMQ,DB: Evento persistido<br/>Sin impacto en usuario
```

### Flujo Detallado

**Comunicación Asíncrona:**

```ruby
# clientes-service/use_cases/create_cliente.rb
saved_cliente = repository.save(cliente)    # ⏱️ 50ms

AuditPublisher.publish(event)               # ⏱️ < 5ms (no espera respuesta)
                                            # ✅ Si auditoría cae, mensaje queda en cola

return saved_cliente                         # Total: ~55ms (40x más rápido!)
```

## 🐰 Rol de RabbitMQ

### ¿Qué es RabbitMQ?

RabbitMQ es un **message broker** (intermediario de mensajes) que funciona como un "buzón de correo" entre servicios:

- **Productores** (clientes/facturas-service): Publican mensajes
- **Cola** (queue): Almacena mensajes temporalmente
- **Consumidor** (este worker): Lee y procesa mensajes

### Ventajas de usar RabbitMQ

| Característica       | Beneficio                                          |
| -------------------- | -------------------------------------------------- |
| **Desacoplamiento**  | Clientes/Facturas no necesitan conocer auditoría   |
| **Resiliencia**      | Si auditoría está caída, mensajes quedan en cola   |
| **Retry automático** | RabbitMQ reintenta enviar mensajes fallidos        |
| **Persistencia**     | Mensajes sobreviven a reinicios de RabbitMQ        |
| **Fair dispatch**    | Distribuye carga entre múltiples consumers         |
| **Confirmación**     | Solo elimina mensaje si fue procesado exitosamente |

### Características de la Cola `audit_events`

```ruby
# shared/messaging/rabbit_connection.rb
queue = channel.queue('audit_events',
  durable: true,              # Cola sobrevive a reinicios
  arguments: {
    'x-message-ttl' => 86400000,  # Mensajes expiran en 24 horas
    'x-max-length' => 100000       # Máximo 100k mensajes en cola
  }
)
```

## 🔧 Funcionamiento del Consumer

### Inicialización

```ruby
def initialize
  @mongo_client = create_mongo_client        # Conexión a MongoDB
  @repository = MongoAuditEventRepository.new(@mongo_client)
  @use_case = CreateAuditEvent.new(audit_event_repository: @repository)
end
```

### Conexión con Retry Logic

```ruby
max_retries = 10
retry_count = 0

begin
  RabbitConnection.instance.connect
  queue = RabbitConnection.instance.audit_queue
rescue StandardError => e
  retry_count += 1
  if retry_count <= max_retries
    puts "Retrying in 3 seconds..."
    sleep 3
    retry
  end
end
```

### Procesamiento de Mensajes

```ruby
queue.subscribe(manual_ack: true, block: true) do |delivery_info, properties, body|
  event = JSON.parse(body)

  # Guardar en MongoDB
  @use_case.execute(
    entity_type: event[:entity_type],
    entity_id: event[:entity_id],
    action: event[:action],
    details: event[:details],
    status: event[:status],
    timestamp: event[:timestamp]
  )

  # ✅ Confirmar procesamiento (elimina mensaje de la cola)
  channel.ack(delivery_info.delivery_tag)

rescue JSON::ParserError => e
  # ❌ Mensaje inválido, descartar (no reintentar)
  channel.nack(delivery_info.delivery_tag, false, false)

rescue StandardError => e
  # ⚠️ Error temporal, reintentar (requeue)
  channel.nack(delivery_info.delivery_tag, false, true)
end
```

### Estrategia de ACK/NACK

| Escenario              | Acción                    | Razón                                   |
| ---------------------- | ------------------------- | --------------------------------------- |
| Evento guardado OK     | `ack(tag)`                | Elimina mensaje, procesado exitosamente |
| JSON inválido          | `nack(tag, false, false)` | Descarta mensaje, nunca será válido     |
| Error MongoDB temporal | `nack(tag, false, true)`  | Reintenta, puede ser transitorio        |

```mermaid
flowchart TD
    Start([Recibir mensaje]) --> Parse{JSON.parse}
    Parse -->|Éxito| Save[Guardar en MongoDB]
    Parse -->|Error| Invalid[JSON inválido]

    Save -->|Éxito| ACK[✅ ACK<br/>Eliminar mensaje]
    Save -->|Error| Temp{¿Error<br/>temporal?}

    Temp -->|Sí| NACK_R[⚠️ NACK + Requeue<br/>Reintentar después]
    Temp -->|No| NACK_D[❌ NACK sin Requeue<br/>Descartar mensaje]

    Invalid --> NACK_D

    ACK --> End([Fin])
    NACK_R --> Queue[Mensaje vuelve<br/>a la cola]
    NACK_D --> Dead[Mensaje descartado]

    Queue --> End
    Dead --> End

    style ACK fill:#4caf50,stroke:#2e7d32,color:#fff
    style NACK_R fill:#ff9800,stroke:#e65100,color:#fff
    style NACK_D fill:#f44336,stroke:#c62828,color:#fff
    style Invalid fill:#f44336,stroke:#c62828,color:#fff
```

## 🚀 Ejecución

### En Docker (Recomendado)

```bash
# El consumer corre automáticamente como servicio
docker-compose up -d

# Ver logs en tiempo real
docker-compose logs -f auditoria-consumer

# Reiniciar consumer
docker-compose restart auditoria-consumer
```

### Manual (Desarrollo Local)

```bash
cd auditoria-service

# Configurar variables de entorno
export RABBITMQ_URL=amqp://admin:factumarket_rabbit_2025@localhost:5672
export MONGO_URL=localhost:27017
export MONGO_DATABASE=auditoria_db
export MONGO_USERNAME=admin
export MONGO_PASSWORD=factumarket_secure_2025

# Ejecutar worker
bundle exec ruby workers/audit_consumer.rb
```

## 📊 Monitoreo

### Ver Estado de la Cola

```bash
# Listar colas y mensajes pendientes
docker-compose exec rabbitmq rabbitmqctl list_queues name messages messages_ready messages_unacknowledged

# Salida esperada:
# audit_events    0    0    0
#                 │    │    └── Mensajes siendo procesados
#                 │    └──────── Mensajes listos para consumir
#                 └───────────── Total de mensajes
```

### Management UI de RabbitMQ

Accede a http://localhost:15672

- **Usuario**: admin
- **Password**: factumarket_rabbit_2025

Desde aquí puedes:

- Ver mensajes en la cola
- Tasa de publicación/consumo
- Gráficas de rendimiento
- Publicar mensajes manualmente (testing)

### Verificar Eventos en MongoDB

```bash
docker-compose exec mongodb mongosh auditoria_db \
  --username admin \
  --password factumarket_secure_2025 \
  --authenticationDatabase admin \
  --eval "db.audit_events.find().sort({created_at:-1}).limit(5).pretty()"
```

## 📚 Referencias

- [RabbitMQ Tutorials](https://www.rabbitmq.com/tutorials)
- [Bunny Gem Documentation](https://github.com/ruby-amqp/bunny)
- [Message Queue Patterns](https://www.enterpriseintegrationpatterns.com/patterns/messaging/)

---
