class CreatePlaceholderFeatureTables < ActiveRecord::Migration[8.1]
  def change
    # Phase 1B: Roles & Permissions
    create_table :roles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.timestamps
    end

    create_table :permissions do |t|
      t.string :key, null: false
      t.string :description
      t.timestamps
    end
    add_index :permissions, :key, unique: true

    create_table :role_permissions do |t|
      t.references :role, null: false, foreign_key: true
      t.references :permission, null: false, foreign_key: true
      t.timestamps
    end
    add_index :role_permissions, [ :role_id, :permission_id ], unique: true

    create_table :user_roles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true
      t.timestamps
    end
    add_index :user_roles, [ :user_id, :role_id ], unique: true

    # Phase 2A: Recurring Transactions
    create_table :recurring_transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.string :description, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.integer :transaction_type, null: false
      t.integer :frequency, null: false
      t.date :next_occurrence, null: false
      t.boolean :active, default: true, null: false
      t.timestamps
    end

    # Phase 2B: Savings Goals
    create_table :savings_goals do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :target_amount, precision: 10, scale: 2, null: false
      t.decimal :current_amount, precision: 10, scale: 2, default: 0, null: false
      t.date :deadline
      t.string :icon
      t.string :color
      t.timestamps
    end

    create_table :savings_contributions do |t|
      t.references :savings_goal, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :note
      t.date :date, null: false
      t.timestamps
    end

    # Phase 2C: Bill Reminders
    create_table :bills do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, foreign_key: true
      t.string :name, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.date :due_date, null: false
      t.integer :frequency, null: false
      t.integer :reminder_days_before, default: 3
      t.boolean :active, default: true, null: false
      t.timestamps
    end

    create_table :bill_payments do |t|
      t.references :bill, null: false, foreign_key: true
      t.references :transaction, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.date :paid_date, null: false
      t.timestamps
    end

    # Phase 3: Notifications
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body
      t.integer :notification_type, null: false
      t.boolean :read, default: false, null: false
      t.string :actionable_url
      t.timestamps
    end
    add_index :notifications, [ :user_id, :read ]

    create_table :notification_preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :notification_type, null: false
      t.boolean :in_app, default: true, null: false
      t.boolean :email, default: false, null: false
      t.timestamps
    end
    add_index :notification_preferences, [ :user_id, :notification_type ], unique: true,
              name: "idx_notification_prefs_user_type"

    # Future: Debt Tracker
    create_table :debt_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :balance, precision: 10, scale: 2, null: false
      t.decimal :interest_rate, precision: 5, scale: 2
      t.decimal :minimum_payment, precision: 10, scale: 2
      t.integer :strategy
      t.timestamps
    end

    # Future: Tags
    create_table :tags do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :color
      t.timestamps
    end
    add_index :tags, [ :user_id, :name ], unique: true

    create_table :transaction_tags do |t|
      t.references :transaction, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.timestamps
    end
    add_index :transaction_tags, [ :transaction_id, :tag_id ], unique: true

    # Future: Subscription Tracker
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, foreign_key: true
      t.string :name, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.integer :frequency, null: false
      t.date :next_billing_date
      t.boolean :active, default: true, null: false
      t.timestamps
    end

    # Future: Wishlist
    create_table :wishlist_items do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :estimated_cost, precision: 10, scale: 2
      t.integer :priority
      t.string :url
      t.text :notes
      t.boolean :purchased, default: false, null: false
      t.timestamps
    end

    # Future: Audit Log
    create_table :audit_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :action, null: false
      t.string :auditable_type, null: false
      t.bigint :auditable_id, null: false
      t.jsonb :changes_json, default: {}
      t.datetime :created_at, null: false
    end
    add_index :audit_logs, [ :auditable_type, :auditable_id ]
    add_index :audit_logs, [ :user_id, :created_at ]
  end
end
