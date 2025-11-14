#!/bin/bash
# Script para ejecutar todos los tests y generar reportes de cobertura
# Uso: ./scripts/run_all_tests.sh

set -e  # Exit on error

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}  RubyDoubleV - Test Suite Runner   ${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Verificar que estamos en la raíz del proyecto
if [ ! -f "Rakefile" ]; then
    echo -e "${YELLOW}Error: Debe ejecutar este script desde la raíz del proyecto${NC}"
    exit 1
fi

# Limpiar reportes anteriores
echo -e "${YELLOW}>>> Limpiando reportes anteriores...${NC}"
rake clean_coverage

# Ejecutar tests
echo ""
echo -e "${BLUE}>>> Ejecutando tests de todos los servicios...${NC}"
rake test

# Generar reportes de cobertura
echo ""
echo -e "${BLUE}>>> Generando reportes de cobertura...${NC}"
rake coverage

# Mostrar resumen
echo ""
echo -e "${BLUE}>>> Resumen de cobertura:${NC}"
rake coverage_summary

echo ""
echo -e "${GREEN}✅ Tests completados!${NC}"
echo ""
echo -e "${YELLOW}Reportes de cobertura disponibles en:${NC}"
echo -e "  - auditoria-service/coverage/index.html"
echo -e "  - clientes-service/coverage/index.html"
echo -e "  - facturas-service/coverage/index.html"
echo ""
