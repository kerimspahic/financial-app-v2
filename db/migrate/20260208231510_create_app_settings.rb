class CreateAppSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :app_settings do |t|
      t.string :key, null: false
      t.string :value

      t.timestamps
    end

    add_index :app_settings, :key, unique: true

    # Seed default exchange rate provider
    AppSetting.create!(key: "exchange_rate_provider", value: "fawazahmed0")
  end
end
