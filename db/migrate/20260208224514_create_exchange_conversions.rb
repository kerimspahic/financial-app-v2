class CreateExchangeConversions < ActiveRecord::Migration[8.1]
  def change
    create_table :exchange_conversions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :from_currency, null: false, limit: 3
      t.string :to_currency, null: false, limit: 3
      t.decimal :from_amount, precision: 15, scale: 4, null: false
      t.decimal :to_amount, precision: 15, scale: 4, null: false
      t.decimal :exchange_rate, precision: 18, scale: 8, null: false
      t.datetime :converted_at, null: false

      t.timestamps
    end

    add_index :exchange_conversions, [ :user_id, :converted_at ],
              name: "idx_exchange_conversions_user_date"
  end
end
