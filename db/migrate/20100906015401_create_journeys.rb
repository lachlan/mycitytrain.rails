class CreateJourneys < ActiveRecord::Migration
  def self.up
    create_table :journeys do |t|
      t.references :origin
      t.references :destination
      t.datetime :depart_at
      t.datetime :arrive_at
    end
    add_index :journeys, [:origin_id, :destination_id, :depart_at], :name => 'journeys_primary_index'
  end

  def self.down
    remove_index :journeys, :journeys_primary_index
    drop_table :journeys
  end
end
