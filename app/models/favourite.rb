class Favourite
  include ActiveModel::Serialization
  include ActiveModel::Validations
  
  validates_presence_of :origin, :destination
  attr_accessor :origin, :destination
  
  # Creates a new Favourite.  
  #
  # origin      - A String naming a location to depart from, or a Location object.
  # destination - A String naming a location to arrive to, or a Location object.
  def initialize(origin, destination)
    @origin, @destination = find_location(origin), find_location(destination)
  end
  
  # Is this Favourite's origin or destination nil or empty?
  #
  # Returns Boolean true if this Favourite is empty, or false otherwise.
  def empty?
    (@origin.nil? or @origin.name.empty?) and (@destination.nil? or destination.name.empty?)
  end
  
  # Reverses the origin and destination locations - useful for return journeys.
  #
  # Returns a new Favourite whose origin is this Favourite's destination, and whose
  # destination is this Favourite's origin.
  def invert
    Favourite.new(@destination.name, @origin.name)
  end

  # List the next 5 departing services for this Favourite journey.
  #
  # Returns an ActiveRecord::Relation list of the next departing Journeys.
  def journeys
    Journey.after(@origin, @destination) unless @origin.nil? or @destination.nil?
  end

  # Get the very last service to depart for this Favourite journey.
  #
  # Returns the last Journey to depart for this Favourite
  def latest
    Journey.latest(@origin, @destination) unless @origin.nil? or @destination.nil?
  end

  private
  # Searches for a matching Location
  #
  # location - A String naming a Location, or a Location object
  #
  # Returns the named Location
  def find_location(location)
    unless location.instance_of? Location
      name = location.to_s
      location = Location.search(name) # look for a matching location in the database
      location = Location.new(:name => name) if location.nil? # if we didn't find a real location, create a fake one
    end    
    location
  end

end

