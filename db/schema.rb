# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_07_16_143250) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "twilio_audio_calls", force: :cascade do |t|
    t.string "recording_url"
    t.text "transcript_data"
    t.bigint "twilio_conversation_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "twilio_call_sid"
    t.string "call_duration"
    t.index ["twilio_conversation_group_id"], name: "index_twilio_audio_calls_on_twilio_conversation_group_id"
  end

  create_table "twilio_conversation_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "twilio_group_members", force: :cascade do |t|
    t.integer "participant_id"
    t.string "phone_number"
    t.string "tag"
    t.bigint "twilio_conversation_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["twilio_conversation_group_id"], name: "index_twilio_group_members_on_twilio_conversation_group_id"
  end

  create_table "twilio_sessions", force: :cascade do |t|
    t.string "call_type"
    t.bigint "twilio_conversation_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "call_status"
    t.boolean "call_extended", default: false
    t.index ["twilio_conversation_group_id"], name: "index_twilio_sessions_on_twilio_conversation_group_id"
  end

  create_table "twilio_video_calls", force: :cascade do |t|
    t.string "room_id"
    t.bigint "twilio_conversation_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "call_duration"
    t.index ["twilio_conversation_group_id"], name: "index_twilio_video_calls_on_twilio_conversation_group_id"
  end

  add_foreign_key "twilio_group_members", "twilio_conversation_groups"
  add_foreign_key "twilio_sessions", "twilio_conversation_groups"
  add_foreign_key "twilio_video_calls", "twilio_conversation_groups"
end
