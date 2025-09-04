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

ActiveRecord::Schema.define(version: 2025_09_04_145511) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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
    t.string "user_role"
    t.boolean "is_disabled", default: false
    t.boolean "can_treat_task", default: false, null: false
    t.string "aircall_phone_number"
    t.bigint "aircall_number_id"
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "aircall_calls", force: :cascade do |t|
    t.bigint "aircall_id"
    t.string "call_uuid"
    t.string "direction"
    t.boolean "answered"
    t.bigint "child_support_id"
    t.bigint "parent_id"
    t.bigint "caller_id", null: false
    t.datetime "started_at"
    t.datetime "answered_at"
    t.datetime "ended_at"
    t.integer "duration"
    t.string "missed_call_reason"
    t.string "asset_url"
    t.integer "call_session"
    t.text "notes", default: [], array: true
    t.text "tags", default: [], array: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["call_uuid"], name: "index_aircall_calls_on_call_uuid"
    t.index ["caller_id"], name: "index_aircall_calls_on_caller_id"
    t.index ["child_support_id"], name: "index_aircall_calls_on_child_support_id"
    t.index ["parent_id"], name: "index_aircall_calls_on_parent_id"
  end

  create_table "aircall_messages", force: :cascade do |t|
    t.string "aircall_id"
    t.string "direction"
    t.bigint "child_support_id"
    t.bigint "parent_id"
    t.bigint "caller_id", null: false
    t.datetime "sent_at"
    t.text "body"
    t.string "status"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["aircall_id"], name: "index_aircall_messages_on_aircall_id"
    t.index ["caller_id"], name: "index_aircall_messages_on_caller_id"
    t.index ["child_support_id"], name: "index_aircall_messages_on_child_support_id"
    t.index ["parent_id"], name: "index_aircall_messages_on_parent_id"
  end

  create_table "answers", force: :cascade do |t|
    t.bigint "question_id", null: false
    t.text "response", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "options", array: true
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "books", force: :cascade do |t|
    t.string "title", null: false
    t.string "ean", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "media_id"
    t.index ["ean"], name: "index_books_on_ean", unique: true
    t.index ["media_id"], name: "index_books_on_media_id"
  end

  create_table "bubble_contents", force: :cascade do |t|
    t.string "bubble_id", null: false
    t.string "age", array: true
    t.string "titre"
    t.string "content_type"
    t.integer "avis_nouveaute"
    t.integer "avis_pas_adapte"
    t.integer "avis_rappel"
    t.text "description"
    t.date "created_date", null: false
    t.bigint "module_content_id"
    t.string "id_contenu"
    t.index ["age"], name: "index_bubble_contents_on_age", using: :gin
    t.index ["module_content_id"], name: "index_bubble_contents_on_module_content_id"
  end

  create_table "bubble_modules", force: :cascade do |t|
    t.string "bubble_id", null: false
    t.text "description"
    t.string "niveau"
    t.string "theme"
    t.string "titre"
    t.date "created_date", null: false
    t.string "age", array: true
    t.bigint "module_precedent_id"
    t.bigint "module_suivant_id"
    t.bigint "video_princ_id"
    t.bigint "video_tem_id"
    t.index ["age"], name: "index_bubble_modules_on_age", using: :gin
    t.index ["module_precedent_id"], name: "index_bubble_modules_on_module_precedent_id"
    t.index ["module_suivant_id"], name: "index_bubble_modules_on_module_suivant_id"
    t.index ["video_princ_id"], name: "index_bubble_modules_on_video_princ_id"
    t.index ["video_tem_id"], name: "index_bubble_modules_on_video_tem_id"
  end

  create_table "bubble_sessions", force: :cascade do |t|
    t.string "bubble_id", null: false
    t.string "avis_contenu"
    t.string "avis_video"
    t.string "child_session"
    t.datetime "derniere_ouverture"
    t.date "created_date"
    t.string "lien"
    t.integer "pourcentage_video"
    t.integer "avis_rappel"
    t.bigint "module_session_id"
    t.bigint "video_id"
    t.datetime "import_date"
    t.bigint "content_id"
    t.index ["content_id"], name: "index_bubble_sessions_on_content_id"
    t.index ["module_session_id"], name: "index_bubble_sessions_on_module_session_id"
    t.index ["video_id"], name: "index_bubble_sessions_on_video_id"
  end

  create_table "bubble_videos", force: :cascade do |t|
    t.string "bubble_id", null: false
    t.integer "like"
    t.integer "dislike"
    t.integer "views"
    t.string "lien"
    t.string "video"
    t.string "video_type"
    t.date "created_date", null: false
    t.integer "avis_rappel"
    t.integer "avis_nouveaute"
    t.integer "avis_pas_adapte"
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
    t.string "call1_reading_frequency"
    t.string "call2_language_awareness"
    t.string "call2_parent_progress"
    t.string "call3_language_awareness"
    t.string "call3_parent_progress"
    t.string "book_not_received"
    t.string "call3_sendings_benefits"
    t.text "call3_sendings_benefits_details"
    t.string "second_language"
    t.string "call1_language_awareness"
    t.text "call1_goals"
    t.string "call2_reading_frequency"
    t.string "call3_reading_frequency"
    t.string "call2_sendings_benefits"
    t.text "call2_sendings_benefits_details"
    t.datetime "discarded_at"
    t.text "call4_technical_information"
    t.text "call4_parent_actions"
    t.text "call4_language_development"
    t.text "call4_goals"
    t.text "call4_notes"
    t.string "call4_status"
    t.text "call4_status_details"
    t.integer "call4_duration"
    t.string "call4_language_awareness"
    t.string "call4_parent_progress"
    t.string "call4_sendings_benefits"
    t.text "call4_sendings_benefits_details"
    t.string "call4_reading_frequency"
    t.text "call5_technical_information"
    t.text "call5_parent_actions"
    t.text "call5_language_development"
    t.text "call5_goals"
    t.text "call5_notes"
    t.string "call5_status"
    t.text "call5_status_details"
    t.integer "call5_duration"
    t.string "call5_language_awareness"
    t.string "call5_parent_progress"
    t.string "call5_sendings_benefits"
    t.text "call5_sendings_benefits_details"
    t.string "call5_reading_frequency"
    t.string "call1_sendings_benefits"
    t.text "call1_sendings_benefits_details"
    t.text "call1_technical_information"
    t.boolean "to_call"
    t.string "books_quantity"
    t.text "notes"
    t.boolean "will_stay_in_group", default: false, null: false
    t.string "availability"
    t.string "call_infos"
    t.string "other_phone_number"
    t.integer "child_count"
    t.string "call1_tv_frequency"
    t.string "call2_tv_frequency"
    t.string "call3_tv_frequency"
    t.string "call4_tv_frequency"
    t.string "call5_tv_frequency"
    t.string "most_present_parent"
    t.boolean "already_working_with"
    t.text "call2_goals_tracking"
    t.text "call3_goals_tracking"
    t.text "call4_goals_tracking"
    t.text "call5_goals_tracking"
    t.string "call2_family_progress"
    t.string "call2_previous_goals_follow_up"
    t.string "parent1_available_support_module_list", array: true
    t.string "parent2_available_support_module_list", array: true
    t.text "call0_parent_actions"
    t.text "call0_language_development"
    t.text "call0_notes"
    t.string "call0_status"
    t.string "call0_parent_progress"
    t.integer "call0_duration"
    t.string "call0_reading_frequency"
    t.string "call0_language_awareness"
    t.text "call0_goals"
    t.string "call0_sendings_benefits"
    t.text "call0_sendings_benefits_details"
    t.text "call0_technical_information"
    t.string "call0_tv_frequency"
    t.text "call0_status_details"
    t.text "call1_goals_tracking"
    t.string "call1_family_progress"
    t.string "call1_previous_goals_follow_up"
    t.text "call0_goals_sms"
    t.text "call1_goals_sms"
    t.text "call2_goals_sms"
    t.text "call3_goals_sms"
    t.text "call4_goals_sms"
    t.text "call5_goals_sms"
    t.bigint "module2_chosen_by_parents_id"
    t.bigint "module3_chosen_by_parents_id"
    t.bigint "module4_chosen_by_parents_id"
    t.bigint "module5_chosen_by_parents_id"
    t.integer "parent_mid_term_rate"
    t.string "parent_mid_term_reaction"
    t.bigint "module6_chosen_by_parents_id"
    t.string "parental_contexts", array: true
    t.bigint "stop_support_caller_id"
    t.text "stop_support_details"
    t.datetime "stop_support_date"
    t.string "family_support_should_be_stopped"
    t.string "call4_previous_goals_follow_up"
    t.jsonb "suggested_videos_counter", default: [], array: true
    t.string "is_bilingual", default: "2_no_information"
    t.string "call0_attempt"
    t.string "call1_attempt"
    t.string "call2_attempt"
    t.string "call3_attempt"
    t.string "call4_attempt"
    t.string "call5_attempt"
    t.string "call0_review"
    t.string "call1_review"
    t.string "call2_review"
    t.string "call3_review"
    t.string "call4_review"
    t.string "call5_review"
    t.string "call3_previous_goals_follow_up"
    t.datetime "address_suspected_invalid_at"
    t.string "call0_goal_sent"
    t.boolean "call0_talk_needed", default: false, null: false
    t.boolean "call1_talk_needed", default: false, null: false
    t.boolean "call2_talk_needed", default: false, null: false
    t.boolean "call3_talk_needed", default: false, null: false
    t.boolean "call4_talk_needed", default: false, null: false
    t.boolean "call5_talk_needed", default: false, null: false
    t.text "call0_why_talk_needed"
    t.text "call1_why_talk_needed"
    t.text "call2_why_talk_needed"
    t.text "call3_why_talk_needed"
    t.text "call4_why_talk_needed"
    t.text "call5_why_talk_needed"
    t.boolean "has_important_information_parental_consent", default: false, null: false
    t.index ["book_not_received"], name: "index_child_supports_on_book_not_received"
    t.index ["call0_parent_progress"], name: "index_child_supports_on_call0_parent_progress"
    t.index ["call0_reading_frequency"], name: "index_child_supports_on_call0_reading_frequency"
    t.index ["call0_tv_frequency"], name: "index_child_supports_on_call0_tv_frequency"
    t.index ["call1_parent_progress"], name: "index_child_supports_on_call1_parent_progress"
    t.index ["call1_reading_frequency"], name: "index_child_supports_on_call1_reading_frequency"
    t.index ["call1_tv_frequency"], name: "index_child_supports_on_call1_tv_frequency"
    t.index ["call2_language_awareness"], name: "index_child_supports_on_call2_language_awareness"
    t.index ["call2_parent_progress"], name: "index_child_supports_on_call2_parent_progress"
    t.index ["call3_language_awareness"], name: "index_child_supports_on_call3_language_awareness"
    t.index ["call3_parent_progress"], name: "index_child_supports_on_call3_parent_progress"
    t.index ["call4_language_awareness"], name: "index_child_supports_on_call4_language_awareness"
    t.index ["call4_parent_progress"], name: "index_child_supports_on_call4_parent_progress"
    t.index ["call5_language_awareness"], name: "index_child_supports_on_call5_language_awareness"
    t.index ["call5_parent_progress"], name: "index_child_supports_on_call5_parent_progress"
    t.index ["discarded_at"], name: "index_child_supports_on_discarded_at"
    t.index ["module2_chosen_by_parents_id"], name: "index_child_supports_on_module2_chosen_by_parents_id"
    t.index ["module3_chosen_by_parents_id"], name: "index_child_supports_on_module3_chosen_by_parents_id"
    t.index ["module4_chosen_by_parents_id"], name: "index_child_supports_on_module4_chosen_by_parents_id"
    t.index ["module5_chosen_by_parents_id"], name: "index_child_supports_on_module5_chosen_by_parents_id"
    t.index ["module6_chosen_by_parents_id"], name: "index_child_supports_on_module6_chosen_by_parents_id"
    t.index ["parent1_available_support_module_list"], name: "index_child_supports_on_parent1_available_support_module_list", using: :gin
    t.index ["parent2_available_support_module_list"], name: "index_child_supports_on_parent2_available_support_module_list", using: :gin
    t.index ["should_be_read"], name: "index_child_supports_on_should_be_read"
    t.index ["stop_support_caller_id"], name: "index_child_supports_on_stop_support_caller_id"
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
    t.integer "family_redirection_urls_count"
    t.integer "family_redirection_url_visits_count"
    t.integer "family_redirection_url_unique_visits_count"
    t.float "family_redirection_unique_visit_rate"
    t.float "family_redirection_visit_rate"
    t.datetime "discarded_at"
    t.string "security_code"
    t.string "src_url"
    t.string "pmi_detail"
    t.string "group_status", default: "waiting"
    t.date "group_start"
    t.date "group_end"
    t.boolean "available_for_workshops", default: false
    t.string "security_token"
    t.index ["birthdate"], name: "index_children_on_birthdate"
    t.index ["child_support_id"], name: "index_children_on_child_support_id"
    t.index ["discarded_at"], name: "index_children_on_discarded_at"
    t.index ["gender"], name: "index_children_on_gender"
    t.index ["group_id"], name: "index_children_on_group_id"
    t.index ["parent1_id"], name: "index_children_on_parent1_id"
    t.index ["parent2_id"], name: "index_children_on_parent2_id"
  end

  create_table "children_sources", force: :cascade do |t|
    t.bigint "source_id"
    t.bigint "child_id"
    t.string "details"
    t.integer "registration_department"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["child_id"], name: "index_children_sources_on_child_id"
    t.index ["source_id"], name: "index_children_sources_on_source_id"
  end

  create_table "children_support_modules", force: :cascade do |t|
    t.bigint "child_id"
    t.bigint "support_module_id"
    t.bigint "parent_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "available_support_module_list", array: true
    t.date "choice_date"
    t.boolean "is_completed", default: false
    t.boolean "is_programmed", default: false, null: false
    t.integer "module_index"
    t.bigint "book_id"
    t.string "book_condition"
    t.index ["book_id"], name: "index_children_support_modules_on_book_id"
    t.index ["child_id"], name: "index_children_support_modules_on_child_id"
    t.index ["parent_id"], name: "index_children_support_modules_on_parent_id"
    t.index ["support_module_id"], name: "index_children_support_modules_on_support_module_id"
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
    t.string "subject"
    t.integer "spot_hit_status"
    t.string "spot_hit_message_id"
    t.boolean "originated_by_app", default: true, null: false
    t.bigint "workshop_id"
    t.string "parent_response"
    t.bigint "quit_group_child_id"
    t.string "parent_presence"
    t.date "acceptation_date"
    t.boolean "is_support_module_message", default: false, null: false
    t.string "link_sent_substring"
    t.string "aircall_message_id"
    t.string "message_provider"
    t.index ["discarded_at"], name: "index_events_on_discarded_at"
    t.index ["quit_group_child_id"], name: "index_events_on_quit_group_child_id"
    t.index ["related_type", "related_id"], name: "index_events_on_related_type_and_related_id"
    t.index ["type", "spot_hit_message_id"], name: "index_events_on_type_and_spot_hit_message_id"
    t.index ["type"], name: "index_events_on_type"
    t.index ["workshop_id"], name: "index_events_on_workshop_id"
  end

  create_table "field_comments", force: :cascade do |t|
    t.bigint "author_id"
    t.string "related_type"
    t.bigint "related_id"
    t.string "field"
    t.text "content"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["author_id"], name: "index_field_comments_on_author_id"
    t.index ["related_type", "related_id"], name: "index_field_comments_on_related_type_and_related_id"
  end

  create_table "foo", id: false, force: :cascade do |t|
    t.integer "x"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name"
    t.date "started_at"
    t.date "ended_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "discarded_at"
    t.integer "support_modules_count", default: 0, null: false
    t.boolean "is_programmed", default: false, null: false
    t.integer "support_module_programmed", default: 0
    t.integer "expected_children_number"
    t.date "call0_start_date"
    t.date "call0_end_date"
    t.date "call1_start_date"
    t.date "call1_end_date"
    t.date "call2_start_date"
    t.date "call2_end_date"
    t.date "call3_start_date"
    t.date "call3_end_date"
    t.boolean "is_excluded_from_analytics", default: false, null: false
    t.boolean "enable_calls_recording", default: false, null: false
    t.jsonb "support_module_sent_dates"
    t.index ["discarded_at"], name: "index_groups_on_discarded_at"
    t.index ["ended_at"], name: "index_groups_on_ended_at"
    t.index ["started_at"], name: "index_groups_on_started_at"
  end

  create_table "media", force: :cascade do |t|
    t.string "type"
    t.string "name"
    t.string "url"
    t.text "body1"
    t.text "body2"
    t.text "body3"
    t.datetime "discarded_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "folder_id"
    t.bigint "image1_id"
    t.bigint "image2_id"
    t.bigint "image3_id"
    t.string "theme"
    t.bigint "link1_id"
    t.bigint "link2_id"
    t.bigint "link3_id"
    t.string "spot_hit_id"
    t.string "airtable_id"
    t.index ["airtable_id"], name: "index_media_on_airtable_id", unique: true
    t.index ["discarded_at"], name: "index_media_on_discarded_at"
    t.index ["folder_id"], name: "index_media_on_folder_id"
    t.index ["image1_id"], name: "index_media_on_image1_id"
    t.index ["image2_id"], name: "index_media_on_image2_id"
    t.index ["image3_id"], name: "index_media_on_image3_id"
    t.index ["link1_id"], name: "index_media_on_link1_id"
    t.index ["link2_id"], name: "index_media_on_link2_id"
    t.index ["link3_id"], name: "index_media_on_link3_id"
    t.index ["type"], name: "index_media_on_type"
  end

  create_table "media_folders", force: :cascade do |t|
    t.bigint "parent_id"
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["parent_id"], name: "index_media_folders_on_parent_id"
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
    t.datetime "discarded_at"
    t.boolean "present_on_whatsapp"
    t.boolean "follow_us_on_whatsapp"
    t.string "degree"
    t.boolean "degree_in_france"
    t.string "help_my_child_to_learn_is_important"
    t.string "would_like_to_do_more"
    t.string "would_receive_advices"
    t.boolean "family_followed", default: false
    t.string "security_code"
    t.integer "mid_term_rate"
    t.string "mid_term_reaction"
    t.text "mid_term_speech"
    t.boolean "is_excluded_from_workshop", default: false
    t.string "degree_level_at_registration"
    t.string "degree_country_at_registration"
    t.string "preferred_channel"
    t.text "is_ambassador_detail"
    t.string "aircall_id"
    t.jsonb "aircall_datas"
    t.string "address_supplement"
    t.string "security_token"
    t.string "book_delivery_organisation_name"
    t.string "book_delivery_location"
    t.index ["address"], name: "index_parents_on_address"
    t.index ["city_name"], name: "index_parents_on_city_name"
    t.index ["discarded_at"], name: "index_parents_on_discarded_at"
    t.index ["email"], name: "index_parents_on_email"
    t.index ["first_name"], name: "index_parents_on_first_name"
    t.index ["gender"], name: "index_parents_on_gender"
    t.index ["is_ambassador"], name: "index_parents_on_is_ambassador"
    t.index ["job"], name: "index_parents_on_job"
    t.index ["last_name"], name: "index_parents_on_last_name"
    t.index ["phone_number_national"], name: "index_parents_on_phone_number_national"
    t.index ["postal_code"], name: "index_parents_on_postal_code"
  end

  create_table "parents_answers", force: :cascade do |t|
    t.bigint "parent_id", null: false
    t.bigint "answer_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["answer_id"], name: "index_parents_answers_on_answer_id"
    t.index ["parent_id"], name: "index_parents_answers_on_parent_id"
  end

  create_table "parents_registrations", force: :cascade do |t|
    t.bigint "parent1_id"
    t.bigint "parent2_id"
    t.boolean "target_profile", default: true, null: false
    t.string "parent1_phone_number", null: false
    t.string "parent2_phone_number"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["parent1_id"], name: "index_parents_registrations_on_parent1_id"
    t.index ["parent2_id"], name: "index_parents_registrations_on_parent2_id"
  end

  create_table "parents_workshops", id: false, force: :cascade do |t|
    t.bigint "parent_id"
    t.bigint "workshop_id"
    t.index ["parent_id"], name: "index_parents_workshops_on_parent_id"
    t.index ["workshop_id"], name: "index_parents_workshops_on_workshop_id"
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text "content"
    t.string "searchable_type"
    t.bigint "searchable_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable_type_and_searchable_id"
  end

  create_table "questions", force: :cascade do |t|
    t.bigint "survey_id", null: false
    t.text "name", null: false
    t.boolean "with_open_ended_response", default: false, null: false
    t.text "uid", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "order", null: false
    t.index ["survey_id"], name: "index_questions_on_survey_id"
    t.index ["uid"], name: "index_questions_on_uid", unique: true
  end

  create_table "redirection_targets", force: :cascade do |t|
    t.integer "redirection_urls_count"
    t.integer "family_redirection_url_visits_count"
    t.integer "family_redirection_url_unique_visits_count"
    t.float "family_unique_visit_rate"
    t.float "family_visit_rate"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "family_redirection_urls_count"
    t.datetime "discarded_at"
    t.bigint "medium_id"
    t.index ["discarded_at"], name: "index_redirection_targets_on_discarded_at"
    t.index ["medium_id"], name: "index_redirection_targets_on_medium_id", unique: true
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
    t.datetime "discarded_at"
    t.index ["child_id"], name: "index_redirection_urls_on_child_id"
    t.index ["discarded_at"], name: "index_redirection_urls_on_discarded_at"
    t.index ["parent_id"], name: "index_redirection_urls_on_parent_id"
    t.index ["redirection_target_id"], name: "index_redirection_urls_on_redirection_target_id"
  end

  create_table "sources", force: :cascade do |t|
    t.string "name", null: false
    t.string "channel", null: false
    t.integer "department"
    t.string "utm"
    t.text "comment"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "is_archived", default: false, null: false
  end

  create_table "support_module_weeks", force: :cascade do |t|
    t.bigint "support_module_id", null: false
    t.bigint "medium_id"
    t.integer "position", default: 0, null: false
    t.boolean "has_been_sent1", default: false, null: false
    t.boolean "has_been_sent2", default: false, null: false
    t.boolean "has_been_sent3", default: false, null: false
    t.integer "additional_medium_id"
    t.boolean "has_been_sent4", default: false, null: false
    t.index ["additional_medium_id"], name: "index_support_module_weeks_on_additional_medium_id"
    t.index ["medium_id"], name: "index_support_module_weeks_on_medium_id"
    t.index ["position"], name: "index_support_module_weeks_on_position"
    t.index ["support_module_id"], name: "index_support_module_weeks_on_support_module_id"
  end

  create_table "support_modules", force: :cascade do |t|
    t.string "name"
    t.datetime "discarded_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.date "start_at"
    t.boolean "for_bilingual", default: false, null: false
    t.string "theme"
    t.string "age_ranges", array: true
    t.integer "level"
    t.bigint "book_id"
    t.index ["age_ranges"], name: "index_support_modules_on_age_ranges", using: :gin
    t.index ["book_id"], name: "index_support_modules_on_book_id"
    t.index ["discarded_at"], name: "index_support_modules_on_discarded_at"
  end

  create_table "surveys", force: :cascade do |t|
    t.text "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.string "taggable_type"
    t.integer "taggable_id"
    t.string "tagger_type"
    t.integer "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at"
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "taggings_taggable_context_idx"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "taggings_count", default: 0
    t.string "color"
    t.boolean "is_visible_by_callers_and_animators", default: false, null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
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
    t.datetime "discarded_at"
    t.string "status"
    t.bigint "treated_by_id"
    t.index ["assignee_id"], name: "index_tasks_on_assignee_id"
    t.index ["description"], name: "index_tasks_on_description"
    t.index ["discarded_at"], name: "index_tasks_on_discarded_at"
    t.index ["done_at"], name: "index_tasks_on_done_at"
    t.index ["due_date"], name: "index_tasks_on_due_date"
    t.index ["related_type", "related_id"], name: "index_tasks_on_related_type_and_related_id"
    t.index ["reporter_id"], name: "index_tasks_on_reporter_id"
    t.index ["title"], name: "index_tasks_on_title"
    t.index ["treated_by_id"], name: "index_tasks_on_treated_by_id"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.datetime "created_at"
    t.jsonb "object"
    t.jsonb "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["whodunnit"], name: "index_versions_on_whodunnit"
  end

  create_table "workshops", force: :cascade do |t|
    t.string "topic"
    t.string "co_animator"
    t.date "workshop_date", null: false
    t.string "address", null: false
    t.string "postal_code", null: false
    t.string "city_name", null: false
    t.string "name"
    t.text "invitation_message", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "animator_id", null: false
    t.string "workshop_land"
    t.string "location"
    t.boolean "canceled", default: false, null: false
    t.string "address_supplement"
    t.datetime "scheduled_invitation_date_time"
    t.index ["animator_id"], name: "index_workshops_on_animator_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "aircall_calls", "admin_users", column: "caller_id"
  add_foreign_key "aircall_messages", "admin_users", column: "caller_id"
  add_foreign_key "books", "media", column: "media_id"
  add_foreign_key "bubble_contents", "bubble_modules", column: "module_content_id"
  add_foreign_key "bubble_modules", "bubble_modules", column: "module_precedent_id"
  add_foreign_key "bubble_modules", "bubble_modules", column: "module_suivant_id"
  add_foreign_key "bubble_modules", "bubble_videos", column: "video_princ_id"
  add_foreign_key "bubble_modules", "bubble_videos", column: "video_tem_id"
  add_foreign_key "bubble_sessions", "bubble_contents", column: "content_id"
  add_foreign_key "bubble_sessions", "bubble_modules", column: "module_session_id"
  add_foreign_key "bubble_sessions", "bubble_videos", column: "video_id"
  add_foreign_key "child_supports", "admin_users", column: "stop_support_caller_id"
  add_foreign_key "child_supports", "admin_users", column: "supporter_id"
  add_foreign_key "child_supports", "support_modules", column: "module2_chosen_by_parents_id"
  add_foreign_key "child_supports", "support_modules", column: "module3_chosen_by_parents_id"
  add_foreign_key "child_supports", "support_modules", column: "module4_chosen_by_parents_id"
  add_foreign_key "child_supports", "support_modules", column: "module5_chosen_by_parents_id"
  add_foreign_key "child_supports", "support_modules", column: "module6_chosen_by_parents_id"
  add_foreign_key "children", "parents", column: "parent1_id"
  add_foreign_key "children", "parents", column: "parent2_id"
  add_foreign_key "children_support_modules", "books"
  add_foreign_key "events", "workshops"
  add_foreign_key "field_comments", "admin_users", column: "author_id"
  add_foreign_key "media", "media", column: "image1_id"
  add_foreign_key "media", "media", column: "image2_id"
  add_foreign_key "media", "media", column: "image3_id"
  add_foreign_key "media", "media", column: "link1_id"
  add_foreign_key "media", "media", column: "link2_id"
  add_foreign_key "media", "media", column: "link3_id"
  add_foreign_key "media", "media_folders", column: "folder_id"
  add_foreign_key "media_folders", "media_folders", column: "parent_id"
  add_foreign_key "redirection_targets", "media"
  add_foreign_key "support_module_weeks", "media", column: "additional_medium_id"
  add_foreign_key "support_modules", "books"
  add_foreign_key "taggings", "tags"
  add_foreign_key "tasks", "admin_users", column: "assignee_id"
  add_foreign_key "tasks", "admin_users", column: "reporter_id"
  add_foreign_key "tasks", "admin_users", column: "treated_by_id"
  add_foreign_key "workshops", "admin_users", column: "animator_id"
end
