# Ejemplos de Uso del Sistema FactuMarket

Este documento contiene ejemplos prácticos de uso de los 3 microservicios.

## Flujo Completo: Crear Cliente y Factura

### Paso 1: Iniciar los servicios

```bash
# Con Docker
docker-compose up

# O manualmente (3 terminales)
cd auditoria-service && bundle exec puma config.ru -p 4003
cd clientes-service && bundle exec puma config.ru -p 4001
cd facturas-service && bundle exec puma config.ru -p 4002
```

### Paso 2: Verificar que los servicios están activos

```bash
curl http://localhost:4001/health
curl http://localhost:4002/health
curl http://localhost:4003/health
```

### Paso 3: Crear un cliente

```bash
curl -X POST http://localhost:4001/clientes \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Tienda El Ahorro S.A.S.",
    "identificacion": "900555123",
    "correo": "contacto@elahorro.com",
    "direccion": "Carrera 7 #12-34, Bogotá, Colombia"
  }'
```

**Respuesta esperada:**
```json
{
  "success": true,
  "message": "Cliente creado exitosamente",
  "data": {
    "id": 1,
    "nombre": "Tienda El Ahorro S.A.S.",
    "identificacion": "900555123",
    "correo": "contacto@elahorro.com",
    "direccion": "Carrera 7 #12-34, Bogotá, Colombia",
    "created_at": "2025-01-13T15:30:00.000Z",
    "updated_at": "2025-01-13T15:30:00.000Z"
  }
}
```

### Paso 4: Consultar el cliente creado

```bash
curl http://localhost:4001/clientes/1
```

### Paso 5: Crear una factura para el cliente

```bash
curl -X POST http://localhost:4002/facturas \
  -H "Content-Type: application/json" \
  -d '{
    "cliente_id": 1,
    "fecha_emision": "2025-01-13",
    "monto": 2500000,
    "items": [
      {
        "descripcion": "Laptop Dell Inspiron 15",
        "cantidad": 1,
        "precio_unitario": 1800000,
        "subtotal": 1800000
      },
      {
        "descripcion": "Mouse Logitech",
        "cantidad": 2,
        "precio_unitario": 50000,
        "subtotal": 100000
      },
      {
        "descripcion": "Teclado Mecánico",
        "cantidad": 1,
        "precio_unitario": 600000,
        "subtotal": 600000
      }
    ]
  }'
```

**Respuesta esperada:**
```json
{
  "success": true,
  "message": "Factura creada exitosamente",
  "data": {
    "id": 1,
    "cliente_id": 1,
    "numero_factura": "F-20250113-A1B2C3D4",
    "fecha_emision": "2025-01-13",
    "monto": 2500000.0,
    "estado": "EMITIDA",
    "items": [...],
    "created_at": "2025-01-13T15:35:00.000Z",
    "updated_at": "2025-01-13T15:35:00.000Z"
  }
}
```

### Paso 6: Consultar eventos de auditoría

```bash
# Eventos del cliente
curl http://localhost:4003/auditoria/cliente/1

# Eventos de la factura
curl http://localhost:4003/auditoria/1

# Todos los eventos recientes
curl http://localhost:4003/auditoria?limit=10
```

## Casos de Error

### Error: Cliente no existe al crear factura

```bash
curl -X POST http://localhost:4002/facturas \
  -H "Content-Type: application/json" \
  -d '{
    "cliente_id": 999,
    "fecha_emision": "2025-01-13",
    "monto": 1000000
  }'
```

**Respuesta:**
```json
{
  "success": false,
  "error": "Cliente con ID 999 no existe o no está disponible"
}
```

### Error: Monto inválido

```bash
curl -X POST http://localhost:4002/facturas \
  -H "Content-Type: application/json" \
  -d '{
    "cliente_id": 1,
    "fecha_emision": "2025-01-13",
    "monto": -100
  }'
```

**Respuesta:**
```json
{
  "success": false,
  "error": "Monto debe ser mayor a 0"
}
```

### Error: Cliente duplicado

```bash
curl -X POST http://localhost:4001/clientes \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Otra Empresa",
    "identificacion": "900555123",
    "correo": "otro@example.com",
    "direccion": "Calle 1"
  }'
```

**Respuesta:**
```json
{
  "success": false,
  "error": "Cliente con identificación 900555123 ya existe"
}
```

## Consultas Avanzadas

### Listar facturas por rango de fechas

```bash
curl "http://localhost:4002/facturas?fechaInicio=2025-01-01&fechaFin=2025-01-31"
```

### Filtrar eventos de auditoría por acción

```bash
# Solo eventos de creación
curl "http://localhost:4003/auditoria?action=CREATE&limit=20"

# Solo errores
curl "http://localhost:4003/auditoria?status=ERROR&limit=50"
```

## Testing con Script

Puedes usar este script bash para pruebas automatizadas:

```bash
#!/bin/bash

echo "=== Testing FactuMarket API ==="

# Test 1: Health checks
echo ""
echo "1. Health Checks..."
curl -s http://localhost:4001/health | jq .
curl -s http://localhost:4002/health | jq .
curl -s http://localhost:4003/health | jq .

# Test 2: Crear cliente
echo ""
echo "2. Creando cliente..."
CLIENTE_RESPONSE=$(curl -s -X POST http://localhost:4001/clientes \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Test Cliente S.A.",
    "identificacion": "900999888",
    "correo": "test@example.com",
    "direccion": "Calle Test 123"
  }')

echo $CLIENTE_RESPONSE | jq .
CLIENTE_ID=$(echo $CLIENTE_RESPONSE | jq -r '.data.id')
echo "Cliente ID: $CLIENTE_ID"

# Test 3: Crear factura
echo ""
echo "3. Creando factura..."
FACTURA_RESPONSE=$(curl -s -X POST http://localhost:4002/facturas \
  -H "Content-Type: application/json" \
  -d "{
    \"cliente_id\": $CLIENTE_ID,
    \"fecha_emision\": \"2025-01-13\",
    \"monto\": 1000000,
    \"items\": []
  }")

echo $FACTURA_RESPONSE | jq .
FACTURA_ID=$(echo $FACTURA_RESPONSE | jq -r '.data.id')
echo "Factura ID: $FACTURA_ID"

# Test 4: Consultar auditoría
echo ""
echo "4. Consultando eventos de auditoría..."
sleep 1
curl -s "http://localhost:4003/auditoria/$FACTURA_ID" | jq .

echo ""
echo "=== Testing completado ==="
```

## Colección Postman

También puedes importar esta colección en Postman:

```json
{
  "info": {
    "name": "FactuMarket API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Clientes",
      "item": [
        {
          "name": "Crear Cliente",
          "request": {
            "method": "POST",
            "header": [{"key": "Content-Type", "value": "application/json"}],
            "url": "http://localhost:4001/clientes",
            "body": {
              "mode": "raw",
              "raw": "{\n  \"nombre\": \"Empresa XYZ\",\n  \"identificacion\": \"900123456\",\n  \"correo\": \"contacto@xyz.com\",\n  \"direccion\": \"Calle 1\"\n}"
            }
          }
        }
      ]
    }
  ]
}
```

## Notas

- Todos los servicios deben estar corriendo antes de ejecutar las pruebas
- Los eventos de auditoría se registran de forma asíncrona
- Si MongoDB no está disponible, los servicios seguirán funcionando pero sin auditoría
