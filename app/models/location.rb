require 'open-uri'
require 'nokogiri'

class Location < ActiveRecord::Base
  include Comparable

  has_many :journeys, :finder_sql => 'SELECT journeys.* FROM journeys WHERE journeys.origin_id = #{id} OR journeys.destination_id = #{id}'
  
  validates_presence_of :name
  validates_uniqueness_of :name
    
  def self.refresh
    html = Nokogiri::HTML(open(url))
    tags = html.css('select[name=FromSuburb] option')
    locations = tags.map { |option| option['value'] }.sort
    locations.map { |location| Location.find_or_create_by_name(:name => location.gsub(/ Railway Station/, '')) }
    locations.count
  end
  
  def translink_name
    name + " Railway Station"
  end
  
  def <=> (other)
    self.name <=> other.name
  end
  
  private  
  def self.url
    'http://jp.translink.com.au/TransLinkstationTimetable.asp'
  end
  
end
