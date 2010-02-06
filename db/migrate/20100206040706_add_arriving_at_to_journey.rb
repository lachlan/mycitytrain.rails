class AddArrivingAtToJourney < ActiveRecord::Migration
  def self.up
    add_column :journeys, :arriving_at, :datetime
  end

  def self.down
    remove_column :journeys, :arriving_at
  end
end
