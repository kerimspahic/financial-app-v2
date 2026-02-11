class EnhanceAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :description, :text
    add_column :accounts, :archived_at, :datetime
    add_column :accounts, :balance_goal, :decimal, precision: 12, scale: 2
    add_column :accounts, :position, :integer, default: 0
    add_reference :accounts, :account_group, null: true, foreign_key: true
  end
end
