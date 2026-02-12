class CreateWebhooks < ActiveRecord::Migration[8.1]
  def change
    create_table :webhooks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :url, null: false
      t.jsonb :events, default: []
      t.string :secret, null: false
      t.boolean :active, default: true
      t.datetime :last_triggered_at

      t.timestamps
    end
  end
end
