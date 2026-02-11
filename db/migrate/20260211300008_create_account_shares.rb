class CreateAccountShares < ActiveRecord::Migration[8.1]
  def change
    create_table :account_shares do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :permission_level, default: 0, null: false
      t.string :invitation_token
      t.string :invitation_email
      t.datetime :accepted_at
      t.timestamps
    end

    add_index :account_shares, [ :account_id, :user_id ], unique: true
    add_index :account_shares, :invitation_token, unique: true
  end
end
