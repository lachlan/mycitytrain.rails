class CreateStops < ActiveRecord::Migration
  def self.up
    create_table :stops do |t|
      t.references  :journey
      t.string      :station_name
      t.string      :platform
      t.integer     :departing_seconds
      t.integer     :arriving_seconds
      t.integer     :position
      
      t.timestamps
    end
    
    add_index :stops, [:journey_id, :position]

  end

  def self.down
    drop_table :stops
  end
end
