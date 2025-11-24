# Model Layer (MVC) - ActiveRecord Model for persistence

require 'active_record'

class FacturaModel < ActiveRecord::Base
  self.table_name = 'facturas'

  # IVA percentages allowed in Colombia
  VALID_IVA_PERCENTAGES = [0, 5, 19].freeze

  validates :cliente_id, presence: true
  validates :numero_factura, presence: true, uniqueness: true
  validates :fecha_emision, presence: true
  validates :subtotal, presence: true, numericality: { greater_than: 0 }
  validates :iva_porcentaje, presence: true, inclusion: { in: VALID_IVA_PERCENTAGES }
  validates :iva_valor, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total, presence: true, numericality: { greater_than: 0 }
  validates :estado, presence: true

  serialize :items, coder: JSON

  # Backward compatibility: alias monto to total
  alias_attribute :monto, :total
end
