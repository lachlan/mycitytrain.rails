class AddTimetableTypeToJourney < ActiveRecord::Migration
  def self.up
    add_column :journeys, :timetable_type_id, :integer
    add_column :journeys, :seconds_since_midnight, :integer
  end

  def self.down
    remove_column :journeys, :timetable_type_id
    remove_column :journeys, :seconds_since_midnight
  end
end
