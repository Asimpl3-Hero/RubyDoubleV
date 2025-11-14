#!/bin/bash
# Script para ejecutar solo tests unitarios (rápido)
# Uso: ./scripts/run_unit_tests.sh

set -e  # Exit on error

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  RubyDoubleV - Unit Tests Only Runner   ${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

# Verificar que estamos en la raíz del proyecto
if [ ! -f "Rakefile" ]; then
    echo -e "${YELLOW}Error: Debe ejecutar este script desde la raíz del proyecto${NC}"
    exit 1
fi

# Ejecutar solo tests unitarios
echo -e "${BLUE}>>> Ejecutando tests unitarios (Domain + Application + Infrastructure)...${NC}"
rake test_unit

echo ""
echo -e "${GREEN}✅ Tests unitarios completados!${NC}"
echo ""
echo -e "${YELLOW}Nota: Para ejecutar tests de integración use: rake test${NC}"
echo ""
