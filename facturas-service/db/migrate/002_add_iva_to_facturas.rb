class AddIvaToFacturas < ActiveRecord::Migration[7.0]
  def change
    # Rename monto to subtotal for clarity
    rename_column :facturas, :monto, :subtotal

    # Add IVA fields
    add_column :facturas, :iva_porcentaje, :decimal, precision: 5, scale: 2, null: false, default: 19.0
    add_column :facturas, :iva_valor, :decimal, precision: 10, scale: 2, null: false, default: 0.0
    add_column :facturas, :total, :decimal, precision: 10, scale: 2, null: false, default: 0.0

    # Add index on total for reporting
    add_index :facturas, :total
  end
end
