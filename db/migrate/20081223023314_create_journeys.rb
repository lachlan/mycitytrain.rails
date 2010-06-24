class CreateJourneys < ActiveRecord::Migration
  def self.up
    create_table :journeys do |t|
      t.references  :timetable_type
      t.references  :departing
      t.integer     :departing_seconds
      t.references  :arriving
      t.integer     :arriving_seconds

      t.timestamps
    end

  add_index :journeys, [:timetable_type_id, :departing_seconds, :departing_id, :arriving_id], :name => 'journey_primary'
  end

  def self.down
    drop_table :journeys
  end
end
