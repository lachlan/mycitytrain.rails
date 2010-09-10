require 'open-uri'
require 'nokogiri'

class Location < ActiveRecord::Base
  include Comparable

  has_many :journeys, :finder_sql => 'SELECT journeys.* FROM journeys WHERE journeys.origin_id = #{id} OR journeys.destination_id = #{id}'
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  # Downloads all CityTrain station Locations from the TransLink web site.
  #
  # Returns the Integer count of Locations downloaded.
  def self.refresh
    html = Nokogiri::HTML(open(url))
    tags = html.css('select[name=FromSuburb] option')
    locations = tags.map { |option| option['value'] }.sort
    locations.map { |location| Location.find_or_create_by_name(:name => location.gsub(/ Railway Station/, '')) }
    locations.count
  end
  
  # Converts a Location name to a TransLink formatted CityTrain station name
  #
  # Returns a String that names a TransLink CityTrain station, that can be used
  # when doing service searches against the TransLink web site.
  def translink_name
    # even if the location name retrieved from translink has an apostrophe in it, when requesting journeys 
    # translink's web site won't work if the location has an apostrophe
    name.gsub(/'/, '') + " Railway Station"
  end
  
  # Location spaceship operator: http://en.wikipedia.org/wiki/Spaceship_operator.
  #
  # other - Another Location for comparison with this Location.
  #
  # Returns -1, 0 or 1 if this Location's name is alphanumerically less than, the same
  # or greater than the other Location's name.
  def <=> (other)
    self.name <=> other.name
  end
  
  # Returs a String containing the URL for getting a list of TransLink CityTrain stations.
  def self.url
    'http://jp.translink.com.au/TransLinkstationTimetable.asp'
  end
end
