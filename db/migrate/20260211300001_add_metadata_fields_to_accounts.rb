class AddMetadataFieldsToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :exclude_from_net_worth, :boolean, default: false, null: false
    add_column :accounts, :bank_name, :string
    add_column :accounts, :account_number_masked, :string
    add_column :accounts, :iban, :string
    add_column :accounts, :icon_emoji, :string
    add_column :accounts, :original_loan_amount, :decimal, precision: 12, scale: 2
    add_column :accounts, :loan_term_months, :integer
  end
end
