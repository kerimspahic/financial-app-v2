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

ActiveRecord::Schema[8.1].define(version: 2026_02_08_185448) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
    t.index ["user_id", "date"], name: "idx_transactions_user_date"
    t.index ["user_id", "transaction_type", "date"], name: "idx_transactions_user_type_date"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "user_preferences", force: :cascade do |t|
    t.string "color_mode", default: "green", null: false
    t.datetime "created_at", null: false
    t.integer "per_page", default: 25, null: false
    t.string "theme_mode", default: "system", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_user_preferences_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
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

  add_foreign_key "accounts", "users"
  add_foreign_key "budgets", "categories"
  add_foreign_key "budgets", "users"
  add_foreign_key "categories", "users"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "categories"
  add_foreign_key "transactions", "users"
  add_foreign_key "user_preferences", "users"
end
