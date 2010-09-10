class Journey < ActiveRecord::Base
  include Comparable
  
  @@limit = 5
  
  belongs_to :origin, :class_name => 'Location'
  belongs_to :destination, :class_name => 'Location'
    
  validates_presence_of :origin, :destination, :depart_at, :arrive_at
  
  def self.latest(origin, destination)
    Journey.where(:origin_id => origin, :destination_id => destination).order('depart_at DESC').limit(1).first
  end
  
  def self.after(origin, destination, depart_after, limit = @@limit)
    limit, journeys = limit.to_i, []
    depart_after = Time.zone.now if depart_after.nil? or depart_after < Time.zone.now # only return journeys that haven't departed yet
    if origin.id? and destination.id? # only bother with real locations stored in the database
      unless origin == destination # don't even try and load journeys where the origin equals the destination        
        begin
          journeys = Journey.where(:origin_id => origin, :destination_id => destination).where('depart_at > ?', depart_after).order('depart_at ASC').limit(limit)
          # pull some more journeys if we don't have enough then try again
          count = (Journey.refresh(origin, destination, limit - journeys.length) if journeys.length < limit) || 0
          raise "Journey.refresh did not download any new services for #{origin.name} to #{destination.name}" if count == 0
        rescue => detail
          puts "[ERROR] #{detail}"
          break # ignore errors, we'll just act like there are no services
        end until journeys.length == limit
      end
    end
    journeys
  end
  
  # downloads the given date range of timetabled services for this journey from TransLink
  def self.refresh(origin, destination, limit = @@limit)
    retries, count, latest_journey, limit = 1, 0, latest(origin, destination), limit.to_i
    depart_after = latest_journey.depart_at + 1.minute unless latest_journey.nil?
    depart_after = Time.zone.now if depart_after.nil? or depart_after < Time.zone.now
    
    begin  
      departure_times = []
      arrival_times = []

      #puts "Trying: origin = #{origin.name}, destination = #{destination.name}, limit = #{limit}, depart_after = #{depart_after.to_s}"
      html = Nokogiri::HTML(open(url(origin, destination, depart_after)))      
      rows = html.css('table table + table tr')
      rows.each do |row|
        heading = row.css('td:first-child b').first
        location = row.css('td')[2]
        time = row.css('td')[1]
        
        unless heading.nil? or location.nil? or time.nil?
          if time.content.strip =~ /\+$/
            base = depart_after.midnight + 1.day
          else
            base = depart_after.midnight
          end            
          if heading.content.strip =~ /departing/i
            if location.content.strip == origin.translink_name
              # such a dirty hack to get the time into the correct time zone :-(
              departure_times << DateTime.strptime("#{base.strftime('%Y-%m-%d')} #{time.content.strip}", '%Y-%m-%d %I.%M%P').in_time_zone - Time.zone.utc_offset.seconds
            end
          elsif heading.content.strip =~ /arriving/i
            if location.content.strip == destination.translink_name
              arrival_times << DateTime.strptime("#{base.strftime('%Y-%m-%d')} #{time.content.strip}", '%Y-%m-%d %I.%M%P').in_time_zone - Time.zone.utc_offset.seconds
            end
          end
        end
      end
      departure_times.each_with_index do |dt, idx|
        journey = Journey.where(:origin_id => origin, :destination_id => destination, :depart_at => dt).limit(1).first
        journey = Journey.new if journey.nil?
        
        journey.origin = origin
        journey.destination = destination
        journey.depart_at = dt
        journey.arrive_at = arrival_times[idx]
        journey.save
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
  
  def <=> (other)
    if self.timetable_day < other.timetable_day
      -1
    elsif self.timetable_day > other.timetable_day
      1
    else
      self.depart_at <=> other.depart_at
    end
  end  
  
  def self.url(origin, destination, depart_at = Time.zone.now)
    #"http://jp.translink.com.au/TransLinkFromToTimetable.asp?Origin=#{CGI::escape(origin.translink_name)}&Destination=#{CGI::escape(destination.translink_name)}&Date=#{CGI::escape(depart_at.strftime('%d/%m/%Y'))}"    
    # it's important not to include leading zeroes on the dates or times in this URL :-(
    "http://jp.translink.com.au/TransLinkEnquiry.asp?MaxJourneys=5&PageFrom=TransLinkStationTimetable.asp&Vehicle=Train&WalkDistance=0&FromSuburb=#{CGI::escape(origin.translink_name)}&ToSuburb=#{CGI::escape(destination.translink_name)}&IsAfter=A&JourneyTimeHours=#{CGI::escape(depart_at.strftime('%I').to_i.to_s)}&JourneyTimeMinutes=#{CGI::escape(depart_at.strftime('%M').to_i.to_s)}&JourneyTimeAmPm=#{CGI::escape(depart_at.strftime('%p'))}&Date=#{CGI::escape(depart_at.strftime('%d').to_i.to_s + '/' + depart_at.strftime('%m').to_i.to_s + '/' + depart_at.strftime('%Y'))}"    
  end
end
