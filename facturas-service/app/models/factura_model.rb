# Model Layer (MVC) - ActiveRecord Model for persistence

require 'active_record'

class FacturaModel < ActiveRecord::Base
  self.table_name = 'facturas'

  validates :cliente_id, presence: true
  validates :numero_factura, presence: true, uniqueness: true
  validates :fecha_emision, presence: true
  validates :monto, presence: true, numericality: { greater_than: 0 }
  validates :estado, presence: true

  serialize :items, coder: JSON
end
