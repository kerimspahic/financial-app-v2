class AddCurrencyFieldsToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :currency, :string, default: "USD", null: false
    add_column :transactions, :original_amount, :decimal, precision: 10, scale: 2
    add_column :transactions, :exchange_rate, :decimal, precision: 15, scale: 6
  end
end
