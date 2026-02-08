class AddPerPageToUserPreferences < ActiveRecord::Migration[8.1]
  def change
    add_column :user_preferences, :per_page, :integer, null: false, default: 25
  end
end
