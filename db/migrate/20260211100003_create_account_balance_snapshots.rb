class CreateAccountBalanceSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :account_balance_snapshots do |t|
      t.references :account, null: false, foreign_key: true
      t.decimal :balance, precision: 12, scale: 2, null: false
      t.date :date, null: false

      t.timestamps
    end

    add_index :account_balance_snapshots, [ :account_id, :date ], unique: true
  end
end
