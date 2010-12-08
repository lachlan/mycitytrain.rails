require 'open-uri'
require 'nokogiri'

class Journey < ActiveRecord::Base
  include Comparable
  
  @@limit = 5
  
  belongs_to :origin, :class_name => 'Location'
  belongs_to :destination, :class_name => 'Location'
    
  validates_presence_of :origin, :destination, :depart_at, :arrive_at
  
  # Find the very last Journey to depart.
  #
  # origin      - The Location to depart from.
  # destination - The Location to arrive to.
  #
  # Returns the last Journey or nil if none was found.
  def self.latest(origin, destination)
    uncached do
      Journey.where(:origin_id => origin, :destination_id => destination).order('depart_at DESC').limit(1).first
    end
  end
  
  # List the next departing Journeys after a given time.
  #
  # origin       - The Location to depart from.
  # destination  - The Location to arrive to.
  # depart_after - The Time after which a Journey must depart (default: 
  #                Time.zone.now).  If time is in the past then Time.zone.now is
  #                used instead.
  # limit        - The maximum number of Journeys to be returned (default: 5)
  #
  # Returns an ActiveRecord::Relation result set of Journeys.
  def self.after(origin, destination, depart_after = nil, limit = @@limit)
    limit, journeys = limit.to_i, []
    
    # only return journeys that haven't departed yet
    if depart_after.nil? or depart_after < Time.zone.now 
      depart_after = Time.zone.now
    end
    
    # only bother with real locations stored in the database
    if origin.id? and destination.id? 
      # don't even try and load journeys where the origin equals the destination
      unless origin == destination    
        begin
          journeys = Journey.where(:origin_id => origin, :destination_id => destination).where('depart_at > ?', depart_after).order('depart_at ASC').limit(limit)
          # pull some more journeys if we don't have enough then try again
          count = (Journey.refresh(origin, destination, limit - journeys.length) if journeys.length < limit) || 0
        rescue => detail
          puts "[ERROR] #{detail}"
          break # ignore errors, we'll just act like there are no services
        end until journeys.length == limit
      end
    end
    journeys
  end
  
  # Downloads the next departing timetabled services from TransLink.
  #
  # origin       - The Location to depart from.
  # destination  - The Location to arrive to.
  # limit        - The maximum number of Journeys to download (default: 5).
  #
  # Returns the Integer count of the number of services downloaded.
  # Raises an Exception if no services can be found on the TransLink site.
  def self.refresh(origin, destination, limit = @@limit)
    retries, count, limit, latest_journey = 1, 0, limit.to_i, latest(origin, destination)
    depart_after = latest_journey.depart_at + 1.minute unless latest_journey.nil?
    depart_after = Time.zone.now if depart_after.nil? or depart_after < Time.zone.now
    
    begin  
      departure_times = []
      arrival_times = []

      u = url(origin, destination, depart_after)
      puts "Trying: origin = #{origin.name}, destination = #{destination.name}, limit = #{limit}, depart_after = #{depart_after.to_s}, url = #{u}"
      html = Nokogiri::HTML(open(u))
      # crappy screen scraping logic for the TransLink journey planner
      # will probably break if they change the page AT ALL!
      results = html.css('.subheading .floatLeft')
      results.each do |result|
        depart_time, arrive_time = result.content.split(' - ').map{ |t| parse_translink_time(t.strip, depart_after.midnight) }
        departure_times << depart_time
        arrival_times << arrive_time
      end
      
      departure_times.each_with_index do |dt, idx|
        Journey.create :origin => origin, :destination => destination, :depart_at => dt, :arrive_at => arrival_times[idx]
      end
      raise "No services returned by TransLink for #{origin.name} to #{destination.name}" if departure_times.length == 0
      depart_after = departure_times.last + 1.minute
      count += departure_times.length
    rescue => detail
      if retries > 0
        retries -= 1
        depart_after = depart_after.midnight + 1.day # try starting from the next day
        retry
      else
        raise
      end
    end until count >= limit
    count
  end
  
  def self.parse_translink_time(time_string, after = Time.now)
    base = after.midnight
    base += 1.day if time_string =~ /\+$/
    datetime = DateTime.strptime("#{base.strftime('%Y-%m-%d%z')} #{time_string}", '%Y-%m-%d%z %I.%M%P').in_time_zone.to_time
  end
  
  # Journey spaceship operator: http://en.wikipedia.org/wiki/Spaceship_operator.
  #
  # other - Another Journey for comparison with this Journey.
  #
  # Returns -1, 0 or 1 if this Journey departs before, at the same time, or
  # after the other Journey respectively.
  def <=> (other)
    self.depart_at <=> other.depart_at
  end  
  
  # The URL for getting TransLink Journey Planner search results.
  #
  # origin       - Search for Journeys departing from this Location.
  # destination  - Search for Journeys arriving to this Location.
  # depart_after - Search for Journeys departing after this Time (default: Time.zone.now).
  #
  # Returns a String containing the Journey Planner search results URL.
  def self.url(origin, destination, depart_after = Time.zone.now)
    # it's important not to include leading zeroes on the dates or times in this URL :-(
    "http://mobile.jp.translink.com.au/TransLinkExactEnquiry.asp?ToLoc=#{CGI::escape(origin.translink_name)}%7E%7E%3B#{CGI::escape(origin.translink_name)}%3B#{CGI::escape(origin.translink_name)}%7E%7ELOCATION+NO+WALK%7E%7EONS&FromLoc=#{CGI::escape(destination.translink_name)}%7E%7E%3B#{CGI::escape(destination.translink_name)}%3B#{CGI::escape(destination.translink_name)}%7E%7ELOCATION+NO+WALK%7E%7EONS&Vehicle=train&WalkDistance=0&IsAfter=A&JourneyTimeHours=#{CGI::escape(depart_after.strftime('%I').to_i.to_s)}&JourneyTimeMinutes=#{CGI::escape(depart_after.strftime('%M').to_i.to_s)}&JourneyTimeAmPm=#{CGI::escape(depart_after.strftime('%p'))}&Date=#{CGI::escape(depart_after.strftime('%d').to_i.to_s + '/' + depart_after.strftime('%m').to_i.to_s + '/' + depart_after.strftime('%Y'))}"
  end
end
