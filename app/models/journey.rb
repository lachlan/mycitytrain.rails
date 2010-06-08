class Journey < ActiveRecord::Base
  include Comparable
  
  belongs_to :departing, :class_name => 'Station'
  belongs_to :arriving, :class_name => 'Station'
  belongs_to :timetable_type
  
  has_many :stops, :order => :position
  
  validates_presence_of :departing, :arriving, :departing_seconds
  
  attr_accessor :departing_at
  attr_accessor :arriving_at
  
  named_scope :departing_when, lambda { |start_date| { :conditions => ['timetable_type_id = ? and departing_seconds >= ?', TimetableDay.find_by_wday(start_date.wday).timetable_type_id, start_date.seconds_since_midnight], :order => 'departing_seconds' }  }
  named_scope :departing_from, lambda { |station| { :conditions => ['departing_id = ?', station] }}
  named_scope :arriving_to, lambda { |station| { :conditions => ['arriving_id = ?', station] }}
  named_scope :limit, lambda { |limit| { :limit => limit }}
  
  def <=> (b)    
    (b and b.departing_seconds) ? (departing_seconds ? departing_seconds <=> b.departing_seconds : 1) : ( departing_seconds ? -1 : 0)
  end
      
  def changes
    changes, service, last_stop = [], [], nil
    
    stops.each do |stop|
        if last_stop == stop.station_name
          changes << service
          service = []
        end
        service << stop
        last_stop = stop.station_name
    end
    changes << service if service and !service.empty?
  end

  def self.departing_after(departing_station, arriving_station, departing_at, limit = 10)
    #Record when upcoming journeys are being requested.  Only put it in the upcoming, as today/tommorrow are used during rake populate task
    HistoricJourney.create :departing => departing_station, :arriving => arriving_station
    self.fetch_journeys(:departing => departing_station, :arriving => arriving_station, :from => departing_at, :limit => limit)
  end

  def self.upcoming(departing_station, arriving_station, limit = 10)
    departing_after(departing_station, arriving_station, Time.zone.now, limit)
  end
  
  def self.today(d, a)
    today = Time.zone.now.midnight 
    fetch_date(d, a, today)
  end
  
  def self.fetch_date(d, a, w)
    self.fetch_journeys(:departing => d, :arriving => a, :from => w)
  end
    
  def self.fetch_journeys(o)
    departing, arriving, from, limit = o[:departing], o[:arriving], o[:from], (o[:limit] || 9999)  
    journeys = Journey.departing_from(departing).arriving_to(arriving).departing_when(from).limit(limit)
  
    if journeys.empty?
      
      #Fetch 4 days worth (one day for Monday to Thursday)
      day_deltas = {}
      TimetableType.all.each {|type| day_deltas[type.id] = nil}
      count = day_deltas.count
      index = 0
      while count > 0
        type = TimetableDay.find_by_wday((from + index.days).wday).timetable_type_id
        if !day_deltas[type]
          day_deltas[type] = from + index.days 
          count -= 1
        end
        index += 1
      end
      
      day_deltas.each do |key, day|
        retries = 0
        begin
          CitytrainAPI.journeys departing, arriving, day
        rescue Exception
          retries += 1; sleep 3 #Sleep in between attempts (3 seconds)
          retry if retries < 10
          raise
        end
      end

      journeys = Journey.departing_from(departing).arriving_to(arriving).departing_when(from).limit(limit)
    end
    
    #transpose departing/arriving times
    journeys.each do |j|
      j.departing_at = from.midnight + j.departing_seconds
      j.arriving_at = from.midnight + j.arriving_seconds
    end    
    
    journeys
  end
  
  #Populate stops if they don't exist in the database
  def self.load_stops(departing, arriving, departing_at)
    #kkkk work to do
    journey = Journey.find_by_departing_id_and_arriving_id_and_departing_at(departing, arriving, departing_at)
    journey.load_stops if journey
  end
  
  def load_stops
    if stops and stops.empty?
      retries = 0
      begin
        CitytrainAPI.stops self
      rescue Exception
        retries += 1; sleep 3 #Sleep in between attempts (3 seconds)
        retry if retries < 10
        raise
      end
    end
  end
  
end
