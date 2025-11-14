# Domain Layer - AuditEvent Entity (Clean Architecture)
# This represents the core business entity with no external dependencies

module Domain
  module Entities
    class AuditEvent
      attr_reader :id, :entity_type, :entity_id, :action, :details, :status, :timestamp, :created_at

      def initialize(id: nil, entity_type:, entity_id:, action:, details:, status:, timestamp: nil, created_at: nil)
        @id = id
        @entity_type = entity_type
        @entity_id = entity_id
        @action = action
        @details = details
        @status = status
        @timestamp = timestamp || Time.now.utc.iso8601
        @created_at = created_at || Time.now.utc

        validate!
      end

      def to_h
        {
          id: @id&.to_s,
          entity_type: @entity_type,
          entity_id: @entity_id,
          action: @action,
          details: @details,
          status: @status,
          timestamp: @timestamp,
          created_at: @created_at
        }
      end

      private

      def validate!
        raise ArgumentError, 'entity_type es requerido' if @entity_type.nil? || @entity_type.strip.empty?
        raise ArgumentError, 'action es requerido' if @action.nil? || @action.strip.empty?
        raise ArgumentError, 'details es requerido' if @details.nil? || @details.strip.empty?
        raise ArgumentError, 'status es requerido' if @status.nil? || @status.strip.empty?
        raise ArgumentError, 'status debe ser SUCCESS o ERROR' unless valid_status?(@status)
      end

      def valid_status?(status)
        %w[SUCCESS ERROR].include?(status)
      end
    end
  end
end
