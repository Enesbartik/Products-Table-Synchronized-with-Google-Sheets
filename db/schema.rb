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

ActiveRecord::Schema[8.1].define(version: 2026_08_02_114635) do
  create_table "products", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "last_synced_at"
    t.string "name", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.boolean "sheet_managed", default: false, null: false
    t.integer "stock", default: 0, null: false
    t.string "sync_key", null: false
    t.datetime "updated_at", null: false
    t.index ["sync_key"], name: "index_products_on_sync_key", unique: true
  end
end
