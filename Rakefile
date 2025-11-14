# Rakefile principal para RubyDoubleV - Sistema de Microservicios
# Este archivo centraliza las tareas de testing y cobertura de todos los servicios

require 'fileutils'
require 'json'

# Colores para output en terminal
class String
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def green; colorize(32); end
  def yellow; colorize(33); end
  def red; colorize(31); end
  def blue; colorize(34); end
  def bold; colorize(1); end
end

# Servicios disponibles
SERVICES = %w[auditoria-service clientes-service facturas-service]

# ===== TAREAS PRINCIPALES =====

desc "Ejecutar tests de todos los servicios"
task :test do
  puts "\n#{'='*80}".blue
  puts " Ejecutando tests de todos los microservicios ".center(80).bold.blue
  puts "#{'='*80}\n".blue

  results = {}

  SERVICES.each do |service|
    puts "\n>>> Ejecutando tests de #{service}...".yellow
    success = run_service_tests(service)
    results[service] = success
  end

  print_test_summary(results)
  exit 1 unless results.values.all?
end

desc "Ejecutar solo tests unitarios (sin integración)"
task :test_unit do
  puts "\n#{'='*80}".blue
  puts " Ejecutando tests unitarios (Domain + Application + Infrastructure) ".center(80).bold.blue
  puts "#{'='*80}\n".blue

  results = {}

  SERVICES.each do |service|
    puts "\n>>> Ejecutando tests unitarios de #{service}...".yellow
    success = run_service_unit_tests(service)
    results[service] = success
  end

  print_test_summary(results)
  exit 1 unless results.values.all?
end

desc "Generar reporte de cobertura de todos los servicios"
task :coverage do
  puts "\n#{'='*80}".blue
  puts " Generando reportes de cobertura ".center(80).bold.blue
  puts "#{'='*80}\n".blue

  SERVICES.each do |service|
    puts "\n>>> Generando cobertura para #{service}...".yellow
    generate_coverage(service)
  end

  puts "\n✅ Reportes de cobertura generados:".green
  SERVICES.each do |service|
    coverage_path = "#{service}/coverage/index.html"
    if File.exist?(coverage_path)
      puts "   - #{service}: #{coverage_path}".green
    end
  end
end

desc "Limpiar reportes de cobertura"
task :clean_coverage do
  puts "\n>>> Limpiando reportes de cobertura...".yellow

  SERVICES.each do |service|
    coverage_dir = "#{service}/coverage"
    if Dir.exist?(coverage_dir)
      FileUtils.rm_rf(coverage_dir)
      puts "   ✓ Limpiado: #{coverage_dir}".green
    end
  end
end

desc "Mostrar resumen de cobertura de todos los servicios"
task :coverage_summary do
  puts "\n#{'='*80}".blue
  puts " Resumen de Cobertura de Código ".center(80).bold.blue
  puts "#{'='*80}\n".blue

  SERVICES.each do |service|
    show_coverage_summary(service)
  end
end

# ===== TAREAS POR SERVICIO =====

namespace :auditoria do
  desc "Ejecutar tests del servicio de auditoría"
  task :test do
    run_service_tests('auditoria-service')
  end

  desc "Ejecutar solo tests unitarios de auditoría"
  task :test_unit do
    run_service_unit_tests('auditoria-service')
  end

  desc "Generar cobertura del servicio de auditoría"
  task :coverage do
    generate_coverage('auditoria-service')
  end
end

namespace :clientes do
  desc "Ejecutar tests del servicio de clientes"
  task :test do
    run_service_tests('clientes-service')
  end

  desc "Ejecutar solo tests unitarios de clientes"
  task :test_unit do
    run_service_unit_tests('clientes-service')
  end

  desc "Generar cobertura del servicio de clientes"
  task :coverage do
    generate_coverage('clientes-service')
  end
end

namespace :facturas do
  desc "Ejecutar tests del servicio de facturas"
  task :test do
    run_service_tests('facturas-service')
  end

  desc "Ejecutar solo tests unitarios de facturas"
  task :test_unit do
    run_service_unit_tests('facturas-service')
  end

  desc "Generar cobertura del servicio de facturas"
  task :coverage do
    generate_coverage('facturas-service')
  end
end

# ===== FUNCIONES AUXILIARES =====

def run_service_tests(service)
  Dir.chdir(service) do
    system("bundle exec rspec --format documentation --color")
  end
end

def run_service_unit_tests(service)
  Dir.chdir(service) do
    # Ejecutar solo tests de domain, application e infrastructure (sin integration)
    system("bundle exec rspec spec/domain spec/application spec/infrastructure --format documentation --color")
  end
end

def generate_coverage(service)
  Dir.chdir(service) do
    # Eliminar cobertura anterior
    FileUtils.rm_rf('coverage') if Dir.exist?('coverage')

    # Ejecutar tests con SimpleCov
    success = system("bundle exec rspec")

    if success && File.exist?('coverage/index.html')
      puts "   ✓ Reporte generado: #{service}/coverage/index.html".green
    else
      puts "   ✗ Error generando reporte de #{service}".red
    end
  end
end

def show_coverage_summary(service)
  resultset_path = "#{service}/coverage/.resultset.json"

  unless File.exist?(resultset_path)
    puts "#{service.ljust(25)} #{'No hay datos de cobertura'.yellow}"
    puts "                          #{'Ejecuta: rake coverage'.yellow}"
    return
  end

  begin
    data = JSON.parse(File.read(resultset_path))
    coverage_data = data['RSpec'] || data.values.first

    if coverage_data && coverage_data['coverage']
      total_lines = 0
      covered_lines = 0

      coverage_data['coverage'].each do |file, lines|
        next if file.include?('/spec/') || file.include?('/config/') || file.include?('/db/')

        lines.each do |count|
          next if count.nil?
          total_lines += 1
          covered_lines += 1 if count > 0
        end
      end

      if total_lines > 0
        percentage = (covered_lines.to_f / total_lines * 100).round(2)
        color = percentage >= 90 ? :green : percentage >= 80 ? :yellow : :red

        puts "#{service.ljust(25)} #{percentage.to_s.rjust(6)}% (#{covered_lines}/#{total_lines} líneas)".send(color)
      else
        puts "#{service.ljust(25)} #{'Sin datos'.yellow}"
      end
    end
  rescue => e
    puts "#{service.ljust(25)} #{'Error leyendo datos'.red}"
  end
end

def print_test_summary(results)
  puts "\n#{'='*80}".blue
  puts " Resumen de Tests ".center(80).bold.blue
  puts "#{'='*80}\n".blue

  results.each do |service, success|
    status = success ? "✓ PASSED".green : "✗ FAILED".red
    puts "  #{service.ljust(30)} #{status}"
  end

  puts "\n"

  if results.values.all?
    puts " ✅ TODOS LOS TESTS PASARON ".center(80).bold.green
  else
    puts " ❌ ALGUNOS TESTS FALLARON ".center(80).bold.red
  end

  puts "#{'='*80}\n".blue
end

# ===== TAREAS DE AYUDA =====

desc "Mostrar lista de tareas disponibles"
task :help do
  puts "\n#{'='*80}".blue
  puts " Tareas Rake Disponibles ".center(80).bold.blue
  puts "#{'='*80}\n".blue

  puts "\n🧪 TESTS - Tareas Principales:".bold
  puts "  rake test               - Ejecutar todos los tests de todos los servicios"
  puts "  rake test_unit          - Ejecutar solo tests unitarios (sin integración)"

  puts "\n📊 COBERTURA:".bold
  puts "  rake coverage           - Generar reportes de cobertura de todos los servicios"
  puts "  rake coverage_summary   - Mostrar resumen de cobertura"
  puts "  rake clean_coverage     - Limpiar reportes de cobertura"

  puts "\n🔧 TESTS POR SERVICIO:".bold
  puts "  rake auditoria:test     - Tests de auditoría-service"
  puts "  rake auditoria:test_unit- Tests unitarios de auditoría"
  puts "  rake auditoria:coverage - Cobertura de auditoría"

  puts "\n  rake clientes:test      - Tests de clientes-service"
  puts "  rake clientes:test_unit - Tests unitarios de clientes"
  puts "  rake clientes:coverage  - Cobertura de clientes"

  puts "\n  rake facturas:test      - Tests de facturas-service"
  puts "  rake facturas:test_unit - Tests unitarios de facturas"
  puts "  rake facturas:coverage  - Cobertura de facturas"

  puts "\n💡 EJEMPLOS DE USO:".bold.yellow
  puts "  rake test                      # Ejecutar todos los tests"
  puts "  rake coverage                  # Generar cobertura de todos"
  puts "  rake coverage_summary          # Ver resumen de cobertura"
  puts "  rake clientes:test             # Tests solo de clientes"
  puts "  rake test_unit                 # Solo tests unitarios"

  puts "\n#{'='*80}\n".blue
end

# Tarea por defecto
task default: :help
