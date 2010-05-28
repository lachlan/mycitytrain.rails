class Favourite
  attr_accessor :id, :departing, :arriving
  
  @@limit = 5
  
  def initialize(id, departing_code, arriving_code)
    @id = id
    @departing = Station.find_by_code departing_code if departing_code
    @arriving = Station.find_by_code arriving_code if arriving_code
  end
  
  def journeys(limit = @@limit)
    Journey.upcoming(departing, arriving, @@limit)
  end
  
  def return_journeys(limit = @@limit)
    Journey.upcoming(arriving, departing, @@limit)
  end
  
end
