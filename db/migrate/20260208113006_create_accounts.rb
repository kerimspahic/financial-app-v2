class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :name
      t.integer :account_type
      t.decimal :balance, precision: 12, scale: 2, default: 0
      t.string :currency, default: "USD"
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
