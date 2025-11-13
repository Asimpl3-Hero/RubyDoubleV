// Script de inicialización para MongoDB
// Ejecutar con: mongosh auditoria_db < init_mongodb.js

// Usar la base de datos de auditoría
db = db.getSiblingDB('auditoria_db');

// Crear colección de eventos de auditoría con validación
db.createCollection('audit_events', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['entity_type', 'action', 'status', 'timestamp', 'created_at'],
      properties: {
        entity_type: {
          bsonType: 'string',
          description: 'Tipo de entidad (Cliente, Factura, etc.)'
        },
        entity_id: {
          bsonType: ['int', 'null'],
          description: 'ID de la entidad'
        },
        action: {
          bsonType: 'string',
          enum: ['CREATE', 'READ', 'UPDATE', 'DELETE', 'LIST'],
          description: 'Acción realizada'
        },
        details: {
          bsonType: 'string',
          description: 'Detalles del evento'
        },
        status: {
          bsonType: 'string',
          enum: ['SUCCESS', 'ERROR'],
          description: 'Estado del evento'
        },
        timestamp: {
          bsonType: 'string',
          description: 'Timestamp ISO 8601'
        },
        created_at: {
          bsonType: 'date',
          description: 'Fecha de creación del registro'
        }
      }
    }
  }
});

// Crear índices para optimizar consultas
db.audit_events.createIndex({ entity_type: 1, entity_id: 1 });
db.audit_events.createIndex({ created_at: -1 });
db.audit_events.createIndex({ action: 1 });
db.audit_events.createIndex({ status: 1 });
db.audit_events.createIndex({ timestamp: -1 });

print('MongoDB auditoria_db inicializada correctamente');
print('Colección: audit_events creada con validación');
print('Índices creados para optimización de consultas');
