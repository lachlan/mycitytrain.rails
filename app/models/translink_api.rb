require 'rest_client'
require 'nokogiri'


class TranslinkAPI
  
  def self.logger
    RAILS_DEFAULT_LOGGER
  end

  def self.stations
    doc = Nokogiri::HTML(RestClient.get('http://jp.translink.com.au/TransLinkstationTimetable.asp').to_s)
    doc.xpath("//select[@name='FromSuburb']/option").each do |o|
      TlStation.find_or_create_by_code(:name => o.content.strip, :code => o[:value].strip)
    end
  end
  
end