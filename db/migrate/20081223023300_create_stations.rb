class CreateStations < ActiveRecord::Migration
  def self.up
    create_table :stations do |t|
      t.string :code
      t.string :name

      t.timestamps
    end
 
	add_index :stations, :code
	add_index :stations, :name
    
  end

  def self.down
    drop_table :stations
  end
end
