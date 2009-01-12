class CreateStops < ActiveRecord::Migration
  def self.up
    create_table :stops do |t|
      t.references  :journey
      t.string      :station_name
      t.string      :platform
      t.datetime    :departing_at
      t.datetime    :arriving_at
      t.integer     :position
      
      t.timestamps
    end
    
    add_index :stops, [:journey_id, :position]

  end

  def self.down
    drop_table :stops
  end
end
