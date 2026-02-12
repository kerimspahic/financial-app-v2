class AddCustomFieldsToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :custom_fields, :jsonb, default: {}
  end
end
