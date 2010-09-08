class CreateLocations < ActiveRecord::Migration
  def self.up
    create_table :locations do |t|
      t.string :name
    end
    add_index :locations, :name
  end

  def self.down
    remove_index :locations, :name
    drop_table :locations
  end
end
