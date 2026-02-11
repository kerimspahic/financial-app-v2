class AddFieldsToBills < ActiveRecord::Migration[8.1]
  def change
    add_reference :bills, :account, foreign_key: true
    add_column :bills, :auto_pay, :boolean, default: false, null: false
    add_column :bills, :website_url, :string
    add_column :bills, :notes, :text
  end
end
