class Favourite
  attr_reader :departing, :arriving
  
  @@limit = 5
  
  def initialize(departing_code, arriving_code)
    @departing = Station.find_by_code departing_code
    @arriving = Station.find_by_code arriving_code
  end
  
  def journeys(limit = @@limit)
    Journey.upcoming(departing, arriving, @@limit)
  end
  
  def return_journeys(limit = @@limit)
    Journey.upcoming(arriving, departing, @@limit)
  end
  
end
