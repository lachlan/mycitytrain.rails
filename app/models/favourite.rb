class Favourite
  attr_accessor :id, :departing, :arriving
  
  @@limit = 5
  
  def initialize(departing, arriving)
    @departing = (Station.find_by_code(departing) || Station.find_by_name(departing)) if departing      
    @arriving = (Station.find_by_code(arriving) || Station.find_by_name(arriving)) if arriving
  end
  
  def journeys(limit = @@limit)
    Journey.upcoming(departing, arriving, @@limit)
  end
  
  def return_journeys(limit = @@limit)
    Journey.upcoming(arriving, departing, @@limit)
  end
  
end
