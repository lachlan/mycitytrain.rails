class TestData < ActiveRecord::Migration
  def self.up
  	return if RAILS_ENV != 'development'

    # Add some stations
    CitytrainAPI.stations
    
    # Add some journeys
    stations = []
    stations << Station.find_by_code("BNC")
    stations << Station.find_by_code("NPR")
    stations << Station.find_by_code("CRO")
        
    dates = [Time.now, Time.now + 1.day]
    
    stations.each do |departing|
      stations.each do |arriving|
        if departing.code != arriving.code
          dates.each { |departing_on| CitytrainAPI.journeys(departing, arriving, departing_on) }
        end
      end
    end
    
  end

  def self.down
  	return if RAILS_ENV != 'development'
    Stop.destroy_all
    Journey.destroy_all
    Station.destroy_all
  end
end
