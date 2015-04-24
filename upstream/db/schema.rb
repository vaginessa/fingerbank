# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20150424145746) do

  create_table "combinations", force: true do |t|
    t.integer  "dhcp_fingerprint_id"
    t.integer  "user_agent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "device_id"
    t.string   "version"
    t.integer  "dhcp_vendor_id"
    t.integer  "score",               default: 0
    t.integer  "mac_vendor_id"
    t.integer  "submitter_id"
  end

  add_index "combinations", ["dhcp_fingerprint_id"], name: "combinations_dhcp_fingerprint_id_ix", using: :btree
  add_index "combinations", ["dhcp_vendor_id"], name: "combinations_dhcp_vendor_id_ix", using: :btree
  add_index "combinations", ["mac_vendor_id"], name: "combinations_mac_vendor_id_ix", using: :btree
  add_index "combinations", ["user_agent_id"], name: "combinations_user_agent_id_ix", using: :btree

  create_table "conditions", force: true do |t|
    t.string   "value"
    t.integer  "rule_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "key"
  end

  create_table "devices", force: true do |t|
    t.string   "name"
    t.boolean  "mobile"
    t.boolean  "tablet"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id"
    t.boolean  "inherit"
    t.integer  "submitter_id"
    t.boolean  "approved",     default: true
  end

  create_table "dhcp_fingerprints", force: true do |t|
    t.string   "value",      limit: 1000
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dhcp_fingerprints", ["value"], name: "index_dhcp_fingerprints_on_value", length: {"value"=>255}, using: :btree

  create_table "dhcp_vendors", force: true do |t|
    t.string   "value",      limit: 1000
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dhcp_vendors", ["value"], name: "index_dhcp_vendors_on_value", length: {"value"=>255}, using: :btree

  create_table "discoverers", force: true do |t|
    t.integer  "device_id"
    t.integer  "device_rule_id"
    t.integer  "version_rule_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description"
    t.integer  "priority"
    t.string   "version"
  end

  create_table "events", force: true do |t|
    t.text     "value",      limit: 2147483647
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fingerprints_os", force: true do |t|
    t.integer "device_id"
    t.integer "fingerprint_id"
  end

  create_table "mac_vendors", force: true do |t|
    t.string   "name"
    t.string   "mac"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mac_vendors", ["mac"], name: "index_mac_vendors_on_mac", unique: true, using: :btree

  create_table "rules", force: true do |t|
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "device_discoverer_id"
    t.integer  "version_discoverer_id"
  end

  create_table "temp_combinations", force: true do |t|
    t.string   "dhcp_fingerprint", limit: 1000
    t.string   "user_agent",       limit: 1000
    t.string   "dhcp_vendor",      limit: 1000
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_agents", force: true do |t|
    t.string   "value",      limit: 1000
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_agents", ["value"], name: "index_user_agents_on_value", length: {"value"=>255}, using: :btree

  create_table "users", force: true do |t|
    t.string   "github_uid"
    t.string   "name",                            null: false
    t.string   "display_name"
    t.integer  "level",               default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "key"
    t.integer  "requests"
    t.string   "email"
    t.boolean  "blocked"
    t.integer  "timeframed_requests", default: 0
  end

  create_table "watched_combinations", force: true do |t|
    t.integer  "combination_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
