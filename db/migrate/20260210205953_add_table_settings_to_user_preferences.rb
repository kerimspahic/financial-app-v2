class AddTableSettingsToUserPreferences < ActiveRecord::Migration[8.1]
  def change
    add_column :user_preferences, :table_settings, :jsonb, default: {}
  end
end
