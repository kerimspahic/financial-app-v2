class AddStyleModeToUserPreferences < ActiveRecord::Migration[8.1]
  def change
    add_column :user_preferences, :style_mode, :string, default: "modern", null: false
  end
end
