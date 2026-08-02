class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :sync_key, null: false
      t.string :name, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :stock, null: false, default: 0
      t.string :category
      t.boolean :sheet_managed, null: false, default: false
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :products, :sync_key, unique: true
  end
end