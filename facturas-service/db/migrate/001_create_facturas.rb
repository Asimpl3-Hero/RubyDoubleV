class CreateFacturas < ActiveRecord::Migration[7.0]
  def change
    create_table :facturas do |t|
      t.integer :cliente_id, null: false, index: true
      t.string :numero_factura, null: false, index: { unique: true }
      t.date :fecha_emision, null: false, index: true
      t.decimal :monto, precision: 10, scale: 2, null: false
      t.string :estado, null: false, default: 'EMITIDA'
      t.text :items

      t.timestamps
    end
  end
end
