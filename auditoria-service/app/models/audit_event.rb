# Model Layer (MVC) - Audit Event model for MongoDB

class AuditEvent
  attr_accessor :id, :entity_type, :entity_id, :action, :details, :status, :timestamp, :created_at

  def initialize(id: nil, entity_type:, entity_id:, action:, details:, status:, timestamp: nil, created_at: nil)
    @id = id
    @entity_type = entity_type
    @entity_id = entity_id
    @action = action
    @details = details
    @status = status
    @timestamp = timestamp || Time.now.utc.iso8601
    @created_at = created_at || Time.now.utc
  end

  def to_h
    {
      id: @id.to_s,
      entity_type: @entity_type,
      entity_id: @entity_id,
      action: @action,
      details: @details,
      status: @status,
      timestamp: @timestamp,
      created_at: @created_at
    }
  end

  def to_document
    {
      entity_type: @entity_type,
      entity_id: @entity_id,
      action: @action,
      details: @details,
      status: @status,
      timestamp: @timestamp,
      created_at: @created_at
    }
  end

  def self.from_document(doc)
    new(
      id: doc['_id'],
      entity_type: doc['entity_type'],
      entity_id: doc['entity_id'],
      action: doc['action'],
      details: doc['details'],
      status: doc['status'],
      timestamp: doc['timestamp'],
      created_at: doc['created_at']
    )
  end
end
