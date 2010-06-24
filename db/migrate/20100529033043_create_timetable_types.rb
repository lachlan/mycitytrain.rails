class CreateTimetableTypes < ActiveRecord::Migration
  def self.up
    create_table :timetable_types do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :timetable_types
  end
end
