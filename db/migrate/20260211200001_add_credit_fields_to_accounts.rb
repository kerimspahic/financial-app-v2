class AddCreditFieldsToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :credit_limit, :decimal, precision: 12, scale: 2
    add_column :accounts, :interest_rate, :decimal, precision: 5, scale: 2
  end
end
