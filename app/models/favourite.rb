class Favourite
  attr_accessor :id, :departing, :arriving, :origin, :destination
  
  @@limit = 5
  
  def initialize(origin, destination)
    @origin = origin
    @destination = destination
    @departing = find_station origin    
    @arriving = find_station destination
  end
  
  def origin
    if @departing
      @departing.name
    else
      @origin || ""
    end
  end
  
  def destination
    if @arriving
      @arriving.name
    else
      @destination || ""
    end
  end
  
  def empty?
    origin.empty? and destination.empty?
  end
  
  def journeys(limit = @@limit)
    Journey.upcoming(departing, arriving, @@limit)
  end
  
  def return_journeys(limit = @@limit)
    Journey.upcoming(arriving, departing, @@limit)
  end
  
  private
  def find_station(name_or_code)
    (Station.find_by_code(name_or_code) || Station.find_by_name(name_or_code)) if name_or_code
  end
  
end
