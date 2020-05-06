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

ActiveRecord::Schema.define(version: 2020_05_06_091637) do

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
    t.string "name"
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "child_supports", force: :cascade do |t|
    t.text "important_information"
    t.text "call1_parent_actions"
    t.text "call1_language_development"
    t.string "call1_parent_progress"
    t.text "call1_notes"
    t.text "call2_technical_information"
    t.text "call2_parent_actions"
    t.text "call2_language_development"
    t.text "call2_goals"
    t.text "call2_notes"
    t.text "call3_technical_information"
    t.text "call3_parent_actions"
    t.text "call3_language_development"
    t.text "call3_goals"
    t.text "call3_notes"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "supporter_id"
    t.boolean "should_be_read"
    t.string "call1_status"
    t.string "call2_status"
    t.string "call3_status"
    t.text "call1_status_details"
    t.text "call2_status_details"
    t.text "call3_status_details"
    t.integer "call1_duration"
    t.integer "call2_duration"
    t.integer "call3_duration"
    t.integer "call1_books_quantity"
    t.string "call1_reading_frequency"
    t.string "call2_language_awareness"
    t.string "call2_parent_progress"
    t.string "call3_language_awareness"
    t.string "call3_parent_progress"
    t.string "book_not_received"
    t.string "call3_sendings_benefits"
    t.text "call3_sendings_benefits_details"
    t.boolean "is_bilingual"
    t.string "second_language"
    t.string "call1_language_awareness"
    t.text "call1_goals"
    t.string "call2_reading_frequency"
    t.string "call3_reading_frequency"
    t.string "call2_sendings_benefits"
    t.text "call2_sendings_benefits_details"
    t.index ["book_not_received"], name: "index_child_supports_on_book_not_received"
    t.index ["call1_parent_progress"], name: "index_child_supports_on_call1_parent_progress"
    t.index ["call1_reading_frequency"], name: "index_child_supports_on_call1_reading_frequency"
    t.index ["call2_language_awareness"], name: "index_child_supports_on_call2_language_awareness"
    t.index ["call2_parent_progress"], name: "index_child_supports_on_call2_parent_progress"
    t.index ["call3_language_awareness"], name: "index_child_supports_on_call3_language_awareness"
    t.index ["call3_parent_progress"], name: "index_child_supports_on_call3_parent_progress"
    t.index ["should_be_read"], name: "index_child_supports_on_should_be_read"
    t.index ["supporter_id"], name: "index_child_supports_on_supporter_id"
  end

  create_table "children", force: :cascade do |t|
    t.bigint "parent1_id", null: false
    t.bigint "parent2_id"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.date "birthdate", null: false
    t.string "gender"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "should_contact_parent1", default: false, null: false
    t.boolean "should_contact_parent2", default: false, null: false
    t.bigint "child_support_id"
    t.string "registration_source_details"
    t.string "registration_source"
    t.bigint "group_id"
    t.boolean "has_quit_group", default: false, null: false
    t.integer "family_redirection_urls_count"
    t.integer "family_redirection_url_visits_count"
    t.integer "family_redirection_url_unique_visits_count"
    t.float "family_redirection_unique_visit_rate"
    t.float "family_redirection_visit_rate"
    t.index ["birthdate"], name: "index_children_on_birthdate"
    t.index ["child_support_id"], name: "index_children_on_child_support_id"
    t.index ["gender"], name: "index_children_on_gender"
    t.index ["group_id"], name: "index_children_on_group_id"
    t.index ["parent1_id"], name: "index_children_on_parent1_id"
    t.index ["parent2_id"], name: "index_children_on_parent2_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "type"
    t.string "related_type"
    t.bigint "related_id"
    t.datetime "occurred_at"
    t.text "body"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_events_on_discarded_at"
    t.index ["related_type", "related_id"], name: "index_events_on_related_type_and_related_id"
    t.index ["type"], name: "index_events_on_type"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name"
    t.date "started_at"
    t.date "ended_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["ended_at"], name: "index_groups_on_ended_at"
    t.index ["started_at"], name: "index_groups_on_started_at"
  end

  create_table "parents", force: :cascade do |t|
    t.string "gender", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "phone_number", null: false
    t.string "email"
    t.string "address", null: false
    t.string "postal_code", null: false
    t.string "city_name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "phone_number_national"
    t.boolean "is_ambassador"
    t.string "job"
    t.datetime "terms_accepted_at"
    t.string "letterbox_name"
    t.integer "redirection_urls_count"
    t.integer "redirection_url_visits_count"
    t.integer "redirection_url_unique_visits_count"
    t.float "redirection_unique_visit_rate"
    t.float "redirection_visit_rate"
    t.boolean "is_lycamobile"
    t.index ["address"], name: "index_parents_on_address"
    t.index ["city_name"], name: "index_parents_on_city_name"
    t.index ["email"], name: "index_parents_on_email"
    t.index ["first_name"], name: "index_parents_on_first_name"
    t.index ["gender"], name: "index_parents_on_gender"
    t.index ["is_ambassador"], name: "index_parents_on_is_ambassador"
    t.index ["job"], name: "index_parents_on_job"
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

  create_table "redirection_targets", force: :cascade do |t|
    t.string "name"
    t.string "target_url", null: false
    t.integer "redirection_urls_count"
    t.integer "family_redirection_url_visits_count"
    t.integer "family_redirection_url_unique_visits_count"
    t.float "family_unique_visit_rate"
    t.float "family_visit_rate"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "family_redirection_urls_count"
  end

  create_table "redirection_url_visits", force: :cascade do |t|
    t.bigint "redirection_url_id"
    t.datetime "occurred_at"
    t.index ["redirection_url_id"], name: "index_redirection_url_visits_on_redirection_url_id"
  end

  create_table "redirection_urls", force: :cascade do |t|
    t.bigint "redirection_target_id"
    t.bigint "parent_id"
    t.bigint "child_id"
    t.string "security_code"
    t.integer "redirection_url_visits_count"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["child_id"], name: "index_redirection_urls_on_child_id"
    t.index ["parent_id"], name: "index_redirection_urls_on_parent_id"
    t.index ["redirection_target_id"], name: "index_redirection_urls_on_redirection_target_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "reporter_id"
    t.bigint "assignee_id"
    t.string "related_type"
    t.bigint "related_id"
    t.string "title", null: false
    t.text "description"
    t.date "due_date"
    t.date "done_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["assignee_id"], name: "index_tasks_on_assignee_id"
    t.index ["description"], name: "index_tasks_on_description"
    t.index ["done_at"], name: "index_tasks_on_done_at"
    t.index ["due_date"], name: "index_tasks_on_due_date"
    t.index ["related_type", "related_id"], name: "index_tasks_on_related_type_and_related_id"
    t.index ["reporter_id"], name: "index_tasks_on_reporter_id"
    t.index ["title"], name: "index_tasks_on_title"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.text "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "child_supports", "admin_users", column: "supporter_id"
  add_foreign_key "children", "parents", column: "parent1_id"
  add_foreign_key "children", "parents", column: "parent2_id"
  add_foreign_key "tasks", "admin_users", column: "assignee_id"
  add_foreign_key "tasks", "admin_users", column: "reporter_id"
end
