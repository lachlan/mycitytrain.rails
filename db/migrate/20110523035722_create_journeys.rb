class CreateJourneys < ActiveRecord::Migration
  def change
    create_table :journeys do |t|
      t.references :origin
      t.references :destination
      t.datetime :depart_at
      t.datetime :arrive_at
      t.timestamps
    end
    add_index :journeys, [:origin_id, :destination_id, :depart_at], :name => 'journeys_primary_index'
  end
end
