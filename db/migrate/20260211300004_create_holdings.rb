class CreateHoldings < ActiveRecord::Migration[8.1]
  def change
    create_table :holdings do |t|
      t.references :account, null: false, foreign_key: true
      t.string :symbol, null: false
      t.string :name
      t.string :holding_type, default: "stock"
      t.decimal :shares, precision: 15, scale: 6, null: false
      t.decimal :cost_basis_per_share, precision: 12, scale: 4, null: false
      t.decimal :current_price, precision: 12, scale: 4
      t.date :last_price_update
      t.timestamps
    end

    add_index :holdings, [ :account_id, :symbol ], unique: true
  end
end
