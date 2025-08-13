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

ActiveRecord::Schema[8.0].define(version: 2025_06_23_132034) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "filled_formfields", force: :cascade do |t|
    t.bigint "filled_form_id", null: false
    t.bigint "formfield_id", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["filled_form_id"], name: "index_filled_formfields_on_filled_form_id"
    t.index ["formfield_id"], name: "index_filled_formfields_on_formfield_id"
  end

  create_table "filled_forms", force: :cascade do |t|
    t.bigint "form_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "approved", default: false, null: false
    t.datetime "submitted_at"
    t.index ["form_id"], name: "index_filled_forms_on_form_id"
    t.index ["user_id"], name: "index_filled_forms_on_user_id"
  end

  create_table "formfields", force: :cascade do |t|
    t.integer "typefield", default: 0
    t.string "variableName"
    t.text "content"
    t.string "title"
    t.bigint "form_id", null: false
    t.boolean "required"
    t.integer "position"
    t.index ["form_id"], name: "index_formfields_on_form_id"
  end

  create_table "forms", force: :cascade do |t|
    t.string "title"
    t.bigint "stage_id", null: false
    t.index ["stage_id"], name: "index_forms_on_stage_id"
  end

  create_table "participants", force: :cascade do |t|
    t.bigint "workflow_id", null: false
    t.integer "current_progress", default: 0
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_participants_on_user_id"
    t.index ["workflow_id"], name: "index_participants_on_workflow_id"
  end

  create_table "running_stages", force: :cascade do |t|
    t.bigint "running_workflow_id", null: false
    t.bigint "stage_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["running_workflow_id"], name: "index_running_stages_on_running_workflow_id"
    t.index ["stage_id"], name: "index_running_stages_on_stage_id"
  end

  create_table "running_workflows", force: :cascade do |t|
    t.bigint "participant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_id"], name: "index_running_workflows_on_participant_id"
  end

  create_table "stages", force: :cascade do |t|
    t.string "title"
    t.bigint "user_id"
    t.bigint "workflow_id", null: false
    t.integer "position"
    t.boolean "approvable", default: false, null: false
    t.index ["user_id"], name: "index_stages_on_user_id"
    t.index ["workflow_id"], name: "index_stages_on_workflow_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "surname"
    t.string "firstname"
    t.string "username"
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "workflows", force: :cascade do |t|
    t.string "title"
    t.string "status"
    t.bigint "owner_id", null: false
    t.integer "current_stage", default: 0
    t.text "description"
    t.boolean "public", default: false, null: false
    t.index ["owner_id"], name: "index_workflows_on_owner_id"
  end

  add_foreign_key "filled_formfields", "filled_forms"
  add_foreign_key "filled_formfields", "formfields"
  add_foreign_key "filled_forms", "forms"
  add_foreign_key "filled_forms", "users", on_delete: :cascade
  add_foreign_key "formfields", "forms"
  add_foreign_key "forms", "stages"
  add_foreign_key "participants", "users", on_delete: :cascade
  add_foreign_key "participants", "workflows"
  add_foreign_key "running_stages", "running_workflows"
  add_foreign_key "running_stages", "stages"
  add_foreign_key "running_workflows", "participants"
  add_foreign_key "stages", "users", on_delete: :cascade
  add_foreign_key "stages", "workflows"
  add_foreign_key "workflows", "users", column: "owner_id", on_delete: :cascade
end
