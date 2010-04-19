class CreateTlStations < ActiveRecord::Migration
  def self.up
    create_table :tl_stations do |t|
      t.string :code
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :tl_stations
  end
end
