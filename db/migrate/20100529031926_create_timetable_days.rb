class CreateTimetableDays < ActiveRecord::Migration
  def self.up
    create_table :timetable_days do |t|
      t.references :timetable_type
      t.integer :wday

      t.timestamps
    end
    
    add_index :timetable_days, :timetable_type_id
    add_index :timetable_days, :wday
    
  end

  def self.down
    drop_table :timetable_days
  end
end
