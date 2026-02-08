class CreateUserPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :user_preferences do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :theme_mode, null: false, default: "system"
      t.string :color_mode, null: false, default: "green"
      t.timestamps
    end
  end
end
