class CreateStops < ActiveRecord::Migration
  def self.up
    create_table :stops do |t|
      t.references  :journey
      t.references  :station
      t.string      :platform
      t.datetime    :departing_at
      t.datetime    :arriving_at
      t.integer     :position
      
      t.timestamps
    end
  end

  def self.down
    drop_table :stops
  end
end
