# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100529033043) do
  create_table "aliases", :force => true do |t|
    t.integer  "station_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "historic_journeys", :force => true do |t|
    t.integer  "departing_id"
    t.integer  "arriving_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "historic_journeys", ["departing_id", "arriving_id"], :name => "index_historic_journeys_on_departing_id_and_arriving_id"

  create_table "journeys", :force => true do |t|
    t.integer  "timetable_type_id"
    t.integer  "departing_id"
    t.integer  "departing_seconds"
    t.integer  "arriving_id"
    t.integer  "arriving_seconds"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "journeys", ["timetable_type_id", "departing_seconds", "departing_id", "arriving_id"], :name => "index_journeys_on_timetable_type_id_and_departing_seconds_and_departing_id_and_arriving_id"

  create_table "slugs", :force => true do |t|
    t.string   "name"
    t.integer  "sluggable_id"
    t.integer  "sequence",                     :default => 1, :null => false
    t.string   "sluggable_type", :limit => 40
    t.string   "scope",          :limit => 40
    t.datetime "created_at"
  end

  add_index "slugs", ["name", "sluggable_type", "scope", "sequence"], :name => "index_slugs_on_name_and_sluggable_type_and_scope_and_sequence", :unique => true
  add_index "slugs", ["sluggable_id"], :name => "index_slugs_on_sluggable_id"

  create_table "stations", :force => true do |t|
    t.string   "code"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stations", ["code"], :name => "index_stations_on_code"
  add_index "stations", ["name"], :name => "index_stations_on_name"

  create_table "stops", :force => true do |t|
    t.integer  "journey_id"
    t.string   "station_name"
    t.string   "platform"
    t.integer  "departing_seconds"
    t.integer  "arriving_seconds"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stops", ["journey_id", "position"], :name => "index_stops_on_journey_id_and_position"

  create_table "timetable_days", :force => true do |t|
    t.integer  "timetable_type_id"
    t.integer  "wday"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "timetable_days", ["timetable_type_id"], :name => "index_timetable_days_on_timetable_type_id"
  add_index "timetable_days", ["wday"], :name => "index_timetable_days_on_wday"

  create_table "timetable_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tl_stations", :force => true do |t|
    t.string   "code"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tl_stations", ["code"], :name => "index_tl_stations_on_code"
  add_index "tl_stations", ["name"], :name => "index_tl_stations_on_name"

end
