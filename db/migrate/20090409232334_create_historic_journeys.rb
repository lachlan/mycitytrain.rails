class CreateHistoricJourneys < ActiveRecord::Migration
  def self.up
    create_table :historic_journeys do |t|
      t.references :departing
      t.references :arriving

      t.timestamps
    end
    
    add_index :historic_journeys, [:departing_id, :arriving_id]
    
  end

  def self.down
    drop_table :historic_journeys
  end
end
