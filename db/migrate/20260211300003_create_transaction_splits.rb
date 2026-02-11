class CreateTransactionSplits < ActiveRecord::Migration[8.1]
  def change
    create_table :transaction_splits do |t|
      t.references :transaction, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :memo
      t.timestamps
    end
  end
end
