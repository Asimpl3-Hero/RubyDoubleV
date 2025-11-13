# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 1) do
  create_table "facturas", force: :cascade do |t|
    t.integer "cliente_id", null: false
    t.string "numero_factura", null: false
    t.date "fecha_emision", null: false
    t.decimal "monto", precision: 10, scale: 2, null: false
    t.string "estado", default: "EMITIDA", null: false
    t.text "items"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cliente_id"], name: "index_facturas_on_cliente_id"
    t.index ["fecha_emision"], name: "index_facturas_on_fecha_emision"
    t.index ["numero_factura"], name: "index_facturas_on_numero_factura", unique: true
  end
end
