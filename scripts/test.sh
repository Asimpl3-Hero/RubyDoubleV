#!/bin/bash

# FactuMarket - Test Runner Script
# Executes all unit and integration tests across microservices

set -e  # Exit on error

echo "======================================"
echo "FactuMarket - Running All Tests"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to run tests for a service
run_service_tests() {
  local service_name=$1
  local service_dir=$2

  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}Testing: ${service_name}${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  cd "$service_dir"

  # Install dependencies if needed
  if [ ! -d "vendor/bundle" ]; then
    echo "Installing dependencies..."
    bundle install --quiet
  fi

  # Run unit tests
  echo -e "${GREEN}→ Running Unit Tests...${NC}"
  if [ -d "spec/domain" ]; then
    bundle exec rspec spec/domain/ --format documentation
    echo ""
  else
    echo "No unit tests found."
    echo ""
  fi

  # Run integration tests
  echo -e "${GREEN}→ Running Integration Tests...${NC}"
  if [ -d "spec/integration" ]; then
    bundle exec rspec spec/integration/ --format documentation
    echo ""
  else
    echo "No integration tests found."
    echo ""
  fi

  cd - > /dev/null
}

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Project root: $PROJECT_ROOT"
echo ""

# Test each service
run_service_tests "Clientes Service" "$PROJECT_ROOT/clientes-service"
run_service_tests "Facturas Service" "$PROJECT_ROOT/facturas-service"

# Summary
echo ""
echo -e "${GREEN}======================================"
echo "✓ All Tests Completed Successfully"
echo "======================================${NC}"
echo ""
echo "Summary:"
echo "  - Unit Tests: Domain layer business logic"
echo "  - Integration Tests: Microservices communication"
echo ""
echo "Next steps:"
echo "  1. Review test coverage"
echo "  2. Start services: docker-compose up"
echo "  3. Test APIs: http://localhost:4001/docs"
echo ""
