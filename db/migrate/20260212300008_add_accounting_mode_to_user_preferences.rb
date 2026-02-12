class AddAccountingModeToUserPreferences < ActiveRecord::Migration[8.1]
  def change
    add_column :user_preferences, :accounting_mode, :boolean, default: false, null: false
  end
end
