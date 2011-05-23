require 'open-uri'
require 'nokogiri'

class Journey < ActiveRecord::Base
  include Comparable
  
  @@limit = 5
  
  belongs_to :origin, :class_name => 'Location'
  belongs_to :destination, :class_name => 'Location'
    
  validates_presence_of :origin, :destination, :depart_at, :arrive_at
  
  def as_json(options={})
    [self.depart_at.utc.iso8601, self.arrive_at.utc.iso8601]
  end
  
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
    after = latest_journey.depart_at + 1.minute unless latest_journey.nil?
    after = Time.zone.now if after.nil? or after < Time.zone.now

    url = 'http://jp.translink.com.au/travel-information/journey-planner/train-planner'

    agent = Mechanize.new
    begin
      puts "Trying: origin = #{origin.name}, destination = #{destination.name}, limit = #{limit}, after = #{after.to_s}, url = #{url}"
      page = agent.post(url, :FromStation => origin.translink_name, 
                      :ToStation => destination.translink_name, 
                      :TimeSearchMode => 'DepartAt', 
                      :SearchDate => after.strftime('%Y-%m-%d'), 
                      :SearchHour => after.strftime('%I').to_i.to_s, 
                      :SearchMinute => after.strftime('%M').to_i.to_s, 
                      :TimeMeridiem => after.strftime('%p'))
      
      html = Nokogiri::HTML(page.body)

      results = html.css('#optionsTable tbody tr').map do |tr|
        tr.css('td.timetd')[0,2].map { |td| parse_translink_time(td.content.strip, after.midnight) }
      end
      
      results.each do |result|
        Journey.create :origin => origin, :destination => destination, :depart_at => result[0], :arrive_at => result[1]
      end
      raise "No services returned by TransLink for #{origin.name} to #{destination.name}" if results.length == 0
      after = results.last.first + 1.minute
      count += results.length
    rescue => detail
      if retries > 0
        retries -= 1
        after = after.midnight + 1.day # try starting from the next day
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
end