class Favourite
  include ActiveModel::Serialization
  include ActiveModel::Validations
  
  validates_presence_of :origin, :destination
  attr_accessor :origin, :destination
  
  def initialize(origin, destination)
    @origin, @destination = find_location(origin), find_location(destination)
  end
  
  def empty?
    (@origin.nil? or @origin.name.empty?) and (@destination.nil? or destination.name.empty?)
  end
  
  def invert
    Favourite.new(@destination.name, @origin.name)
  end

  def journeys
    Journey.after(@origin, @destination) unless @origin.nil? or @destination.nil?
  end

  def latest
    Journey.latest(@origin, @destination) unless @origin.nil? or @destination.nil?
  end

  private
  def find_location(location)
    unless location.instance_of? Location
      name = location.to_s
      location = Location.where('name like ?', name).limit(1).first # look for a matching location in the database
      location = Location.new(:name => name) if location.nil? # if we didn't find a real location, create a fake one
    end    
    location
  end

end

