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

ActiveRecord::Schema.define(:version => 20100419102954) do

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

  create_table "journey_history", :force => true do |t|
    t.integer  "departing_id"
    t.integer  "arriving_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "journey_history", ["departing_id", "arriving_id"], :name => "index_journey_history_on_departing_id_and_arriving_id"

  create_table "journeys", :force => true do |t|
    t.integer  "departing_id"
    t.datetime "departing_at"
    t.integer  "arriving_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "arriving_at"
  end

  add_index "journeys", ["departing_at", "departing_id", "arriving_id"], :name => "index_journeys_on_departing_at_and_departing_id_and_arriving_id"

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
    t.datetime "departing_at"
    t.datetime "arriving_at"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stops", ["journey_id", "position"], :name => "index_stops_on_journey_id_and_position"

  create_table "tl_stations", :force => true do |t|
    t.string   "code"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tl_stations", ["code"], :name => "index_tl_stations_on_code"
  add_index "tl_stations", ["name"], :name => "index_tl_stations_on_name"

end
