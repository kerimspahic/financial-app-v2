# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_10_205954) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "accounts", force: :cascade do |t|
    t.integer "account_type", null: false
    t.decimal "balance", precision: 12, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.string "currency", default: "USD"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "app_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["key"], name: "index_app_settings_on_key", unique: true
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "auditable_id", null: false
    t.string "auditable_type", null: false
    t.jsonb "changes_json", default: {}
    t.datetime "created_at", null: false
    t.bigint "user_id", null: false
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["user_id", "created_at"], name: "index_audit_logs_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "bill_payments", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.bigint "bill_id", null: false
    t.datetime "created_at", null: false
    t.date "paid_date", null: false
    t.bigint "transaction_id"
    t.datetime "updated_at", null: false
    t.index ["bill_id"], name: "index_bill_payments_on_bill_id"
    t.index ["transaction_id"], name: "index_bill_payments_on_transaction_id"
  end

  create_table "bills", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.date "due_date", null: false
    t.integer "frequency", null: false
    t.string "name", null: false
    t.integer "reminder_days_before", default: 3
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["category_id"], name: "index_bills_on_category_id"
    t.index ["user_id"], name: "index_bills_on_user_id"
  end

  create_table "budgets", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.integer "month", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "year", null: false
    t.index ["category_id"], name: "index_budgets_on_category_id"
    t.index ["user_id", "category_id", "month", "year"], name: "idx_budgets_unique_per_category_month", unique: true
    t.index ["user_id", "month", "year"], name: "idx_budgets_user_month_year"
    t.index ["user_id"], name: "index_budgets_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.integer "category_type", null: false
    t.string "color"
    t.datetime "created_at", null: false
    t.string "icon"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "debt_accounts", force: :cascade do |t|
    t.decimal "balance", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.decimal "interest_rate", precision: 5, scale: 2
    t.decimal "minimum_payment", precision: 10, scale: 2
    t.string "name", null: false
    t.integer "strategy"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_debt_accounts_on_user_id"
  end

  create_table "exchange_conversions", force: :cascade do |t|
    t.datetime "converted_at", null: false
    t.datetime "created_at", null: false
    t.decimal "exchange_rate", precision: 18, scale: 8, null: false
    t.decimal "from_amount", precision: 15, scale: 4, null: false
    t.string "from_currency", limit: 3, null: false
    t.decimal "to_amount", precision: 15, scale: 4, null: false
    t.string "to_currency", limit: 3, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "converted_at"], name: "idx_exchange_conversions_user_date"
    t.index ["user_id"], name: "index_exchange_conversions_on_user_id"
  end

  create_table "notification_preferences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "email", default: false, null: false
    t.boolean "in_app", default: true, null: false
    t.integer "notification_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "notification_type"], name: "idx_notification_prefs_user_type", unique: true
    t.index ["user_id"], name: "index_notification_preferences_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "actionable_url"
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "notification_type", null: false
    t.boolean "read", default: false, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_permissions_on_key", unique: true
  end

  create_table "recurring_transactions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.boolean "active", default: true, null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.integer "frequency", null: false
    t.date "next_occurrence", null: false
    t.integer "transaction_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id"], name: "index_recurring_transactions_on_account_id"
    t.index ["category_id"], name: "index_recurring_transactions_on_category_id"
    t.index ["user_id"], name: "index_recurring_transactions_on_user_id"
  end

  create_table "role_permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "permission_id", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_role_permissions_on_permission_id"
    t.index ["role_id", "permission_id"], name: "index_role_permissions_on_role_id_and_permission_id", unique: true
    t.index ["role_id"], name: "index_role_permissions_on_role_id"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "saved_filters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "filter_params", default: {}
    t.boolean "is_default", default: false, null: false
    t.string "name", null: false
    t.string "page_key", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "page_key", "name"], name: "index_saved_filters_on_user_id_and_page_key_and_name", unique: true
    t.index ["user_id", "page_key"], name: "index_saved_filters_on_user_id_and_page_key"
    t.index ["user_id"], name: "index_saved_filters_on_user_id"
  end

  create_table "savings_contributions", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "note"
    t.bigint "savings_goal_id", null: false
    t.datetime "updated_at", null: false
    t.index ["savings_goal_id"], name: "index_savings_contributions_on_savings_goal_id"
  end

  create_table "savings_goals", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.decimal "current_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.date "deadline"
    t.string "icon"
    t.string "name", null: false
    t.decimal "target_amount", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_savings_goals_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.integer "frequency", null: false
    t.string "name", null: false
    t.date "next_billing_date"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["category_id"], name: "index_subscriptions_on_category_id"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "table_configs", force: :cascade do |t|
    t.jsonb "columns", default: []
    t.datetime "created_at", null: false
    t.jsonb "filters", default: []
    t.string "page_key", null: false
    t.jsonb "search_fields", default: []
    t.datetime "updated_at", null: false
    t.index ["page_key"], name: "index_table_configs_on_page_key", unique: true
  end

  create_table "tags", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "name"], name: "index_tags_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_tags_on_user_id"
  end

  create_table "transaction_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "tag_id", null: false
    t.bigint "transaction_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_transaction_tags_on_tag_id"
    t.index ["transaction_id", "tag_id"], name: "index_transaction_tags_on_transaction_id_and_tag_id", unique: true
    t.index ["transaction_id"], name: "index_transaction_tags_on_transaction_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "description", null: false
    t.text "notes"
    t.integer "transaction_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["description"], name: "idx_transactions_description_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["notes"], name: "idx_transactions_notes_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["user_id", "date"], name: "idx_transactions_user_date"
    t.index ["user_id", "transaction_type", "date"], name: "idx_transactions_user_type_date"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "user_preferences", force: :cascade do |t|
    t.string "color_mode", default: "green", null: false
    t.datetime "created_at", null: false
    t.integer "per_page", default: 25, null: false
    t.jsonb "table_configs", default: {}
    t.jsonb "table_settings", default: {}
    t.string "theme_mode", default: "system", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_user_preferences_on_user_id", unique: true
  end

  create_table "user_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "jti", null: false
    t.string "last_name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "wishlist_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "estimated_cost", precision: 10, scale: 2
    t.string "name", null: false
    t.text "notes"
    t.integer "priority"
    t.boolean "purchased", default: false, null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_wishlist_items_on_user_id"
  end

  add_foreign_key "accounts", "users"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "bill_payments", "bills"
  add_foreign_key "bill_payments", "transactions"
  add_foreign_key "bills", "categories"
  add_foreign_key "bills", "users"
  add_foreign_key "budgets", "categories"
  add_foreign_key "budgets", "users"
  add_foreign_key "categories", "users"
  add_foreign_key "debt_accounts", "users"
  add_foreign_key "exchange_conversions", "users"
  add_foreign_key "notification_preferences", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "recurring_transactions", "accounts"
  add_foreign_key "recurring_transactions", "categories"
  add_foreign_key "recurring_transactions", "users"
  add_foreign_key "role_permissions", "permissions"
  add_foreign_key "role_permissions", "roles"
  add_foreign_key "saved_filters", "users"
  add_foreign_key "savings_contributions", "savings_goals"
  add_foreign_key "savings_goals", "users"
  add_foreign_key "subscriptions", "categories"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "tags", "users"
  add_foreign_key "transaction_tags", "tags"
  add_foreign_key "transaction_tags", "transactions"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "categories"
  add_foreign_key "transactions", "users"
  add_foreign_key "user_preferences", "users"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "wishlist_items", "users"
end
