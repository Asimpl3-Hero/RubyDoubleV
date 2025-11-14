# JWT Communication Logger
# Registra toda la actividad de JWT entre microservicios

require 'time'
require 'json'

module JwtLogger
  LOG_FILE = '/tmp/jwt_communication.log'

  class << self
    def log_token_generation(service_name:, target_url: nil)
      log_entry(
        type: 'TOKEN_GENERATED',
        service: service_name,
        target_url: target_url,
        message: "Token JWT generado para #{service_name}"
      )
    end

    def log_token_validation(issuer:, service:, path:, success:, error: nil)
      log_entry(
        type: success ? 'TOKEN_VALIDATED' : 'TOKEN_REJECTED',
        service: service,
        issuer: issuer,
        path: path,
        success: success,
        error: error,
        message: success ?
          "Token de '#{issuer}' validado exitosamente en '#{service}'" :
          "Token rechazado: #{error}"
      )
    end

    def log_service_communication(from:, to:, endpoint:, method:, success:)
      log_entry(
        type: 'SERVICE_COMMUNICATION',
        from: from,
        to: to,
        endpoint: endpoint,
        method: method,
        success: success,
        message: success ?
          "✅ #{from} → #{to} [#{method} #{endpoint}]" :
          "❌ #{from} → #{to} [#{method} #{endpoint}] FAILED"
      )
    end

    def read_logs(lines: 50)
      return [] unless File.exist?(LOG_FILE)
      File.readlines(LOG_FILE).last(lines)
    end

    def clear_logs
      File.delete(LOG_FILE) if File.exist?(LOG_FILE)
      log_entry(
        type: 'SYSTEM',
        message: '🔄 Log file cleared'
      )
    end

    def summary
      return "No logs found" unless File.exist?(LOG_FILE)

      logs = read_logs(lines: 1000)

      total = logs.size
      generated = logs.count { |l| l.include?('TOKEN_GENERATED') }
      validated = logs.count { |l| l.include?('TOKEN_VALIDATED') }
      rejected = logs.count { |l| l.include?('TOKEN_REJECTED') }
      communications = logs.count { |l| l.include?('SERVICE_COMMUNICATION') }

      <<~SUMMARY
        📊 JWT Communication Summary
        ═══════════════════════════════════════
        Total entries:        #{total}
        Tokens generated:     #{generated}
        Tokens validated:     #{validated} ✅
        Tokens rejected:      #{rejected} ❌
        Service calls:        #{communications}
        ═══════════════════════════════════════
        Last activity: #{logs.last&.strip || 'N/A'}
      SUMMARY
    end

    private

    def log_entry(data)
      timestamp = Time.now.utc.iso8601(3)

      log_line = {
        timestamp: timestamp,
        **data
      }.to_json

      File.open(LOG_FILE, 'a') do |f|
        f.puts log_line
      end

      # También imprimir a stdout para debugging
      puts "[JWT-LOG] #{data[:message]}" if ENV['RACK_ENV'] == 'development'
    rescue => e
      puts "Error writing to JWT log: #{e.message}"
    end
  end
end
