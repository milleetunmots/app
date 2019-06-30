# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_06_30_121038) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "children", force: :cascade do |t|
    t.bigint "parent1_id", null: false
    t.bigint "parent2_id"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.date "birthdate", null: false
    t.string "gender", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "should_contact_parent1", default: false, null: false
    t.boolean "should_contact_parent2", default: false, null: false
    t.index ["birthdate"], name: "index_children_on_birthdate"
    t.index ["gender"], name: "index_children_on_gender"
    t.index ["parent1_id"], name: "index_children_on_parent1_id"
    t.index ["parent2_id"], name: "index_children_on_parent2_id"
  end

  create_table "parents", force: :cascade do |t|
    t.string "gender", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "phone_number", null: false
    t.string "email", null: false
    t.string "address", null: false
    t.string "postal_code", null: false
    t.string "city_name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "phone_number_national"
    t.index ["address"], name: "index_parents_on_address"
    t.index ["city_name"], name: "index_parents_on_city_name"
    t.index ["email"], name: "index_parents_on_email"
    t.index ["first_name"], name: "index_parents_on_first_name"
    t.index ["gender"], name: "index_parents_on_gender"
    t.index ["last_name"], name: "index_parents_on_last_name"
    t.index ["phone_number_national"], name: "index_parents_on_phone_number_national"
    t.index ["postal_code"], name: "index_parents_on_postal_code"
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text "content"
    t.string "searchable_type"
    t.bigint "searchable_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable_type_and_searchable_id"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "children", "parents", column: "parent1_id"
  add_foreign_key "children", "parents", column: "parent2_id"
end
