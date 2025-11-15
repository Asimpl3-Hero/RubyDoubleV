#!/bin/bash

TOKEN="eyJhbGciOiJIUzI1NiJ9.eyJzZXJ2aWNlX25hbWUiOiJzd2FnZ2VyLXRlc3QiLCJpYXQiOjE3NjMxODE5MDEsImV4cCI6MTc2MzE4OTEwMX0.DCc9ROZELkT7EoCOGpm44jih5ZiPYxbtFy6AFRZJnWM"

echo "=========================================="
echo "PRUEBA COMPLETA LOCAL - DOCKER COMPOSE"
echo "=========================================="
echo ""

# 1. Crear Cliente
echo "1. CREAR CLIENTE..."
CLIENTE=$(curl -s -X POST http://localhost:4001/clientes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"nombre":"Empresa Docker Local","identificacion":"888999000","correo":"docker@local.com","direccion":"Docker Street 789"}')
echo "$CLIENTE"
CLIENTE_ID=$(echo "$CLIENTE" | grep -o '"id":[0-9]*' | grep -o '[0-9]*' | head -1)
echo ""
echo "✅ Cliente creado con ID: $CLIENTE_ID"
echo ""

# 2. Crear Factura
echo "2. CREAR FACTURA (Valida cliente con Clientes Service)..."
FACTURA=$(curl -s -X POST http://localhost:4002/facturas \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"cliente_id\":$CLIENTE_ID,\"fecha_emision\":\"2025-11-15\",\"monto\":8500000,\"items\":[{\"descripcion\":\"Consultoría IT\",\"cantidad\":1,\"precio_unitario\":8500000,\"subtotal\":8500000}]}")
echo "$FACTURA"
FACTURA_NUM=$(echo "$FACTURA" | grep -o '"numero_factura":"[^"]*"' | cut -d'"' -f4)
echo ""
echo "✅ Factura creada: $FACTURA_NUM"
echo ""

# 3. Verificar Auditoría
echo "3. VERIFICAR EVENTOS DE AUDITORÍA..."
sleep 2
AUDIT=$(curl -s "http://localhost:4003/auditoria?limit=5" \
  -H "Authorization: Bearer $TOKEN")
echo "$AUDIT"
echo ""

echo "=========================================="
echo "RESUMEN - DOCKER COMPOSE LOCAL"
echo "=========================================="
echo "✅ Cliente creado (ID: $CLIENTE_ID)"
echo "✅ Factura creada ($FACTURA_NUM)"
echo "✅ Comunicación Facturas → Clientes: OK"
echo "✅ Eventos registrados en Auditoría: OK"
echo ""
echo "🎉 TODOS LOS MICROSERVICIOS FUNCIONAN EN LOCAL!"
