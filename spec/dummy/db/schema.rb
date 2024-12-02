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

ActiveRecord::Schema[7.1].define(version: 2024_04_19_175459) do
  # These are extensions that must be enabled in order to support this database
  # TESTTTT
  enable_extension "plpgsql"

  create_table "eventsimple_outbox_cursors", force: :cascade do |t|
    t.string "identifier", null: false
    t.bigint "cursor", null: false
    t.index ["identifier"], name: "index_eventsimple_outbox_cursors_on_identifier", unique: true
  end

  create_table "user_events", force: :cascade do |t|
    t.string "aggregate_id", null: false
    t.string "idempotency_key"
    t.string "type", null: false
    t.json "data", default: {}, null: false
    t.json "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "eventide_position_id"
    t.index ["aggregate_id"], name: "index_user_events_on_aggregate_id"
    t.index ["created_at"], name: "index_user_events_on_created_at"
    t.index ["eventide_position_id"], name: "index_user_events_on_eventide_position_id", unique: true
    t.index ["idempotency_key"], name: "index_user_events_on_idempotency_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "canonical_id", null: false
    t.string "username"
    t.string "email"
    t.integer "lock_version"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["canonical_id"], name: "index_users_on_canonical_id", unique: true
  end

end
