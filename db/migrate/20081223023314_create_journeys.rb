class CreateJourneys < ActiveRecord::Migration
  def self.up
    create_table :journeys do |t|
      t.references  :departing
      t.datetime    :departing_at
      t.references  :arriving

      t.timestamps
    end

  add_index :journeys, [:departing_at, :departing_id, :arriving_id]
  end

  def self.down
    drop_table :journeys
  end
end
