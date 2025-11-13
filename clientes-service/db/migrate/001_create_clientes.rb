class CreateClientes < ActiveRecord::Migration[7.0]
  def change
    create_table :clientes do |t|
      t.string :nombre, null: false
      t.string :identificacion, null: false, index: { unique: true }
      t.string :correo, null: false
      t.text :direccion, null: false

      t.timestamps
    end
  end
end
