# Model Layer (MVC) - ActiveRecord Model for persistence

require 'active_record'

class ClienteModel < ActiveRecord::Base
  self.table_name = 'clientes'

  validates :nombre, presence: true
  validates :identificacion, presence: true, uniqueness: true
  validates :correo, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :direccion, presence: true
end
