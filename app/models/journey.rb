class Journey < ActiveRecord::Base
  include Comparable
  
  belongs_to :departing, :class_name => 'Station'
  belongs_to :arriving, :class_name => 'Station'
  belongs_to :timetable_type
  
  has_many :stops, :order => :position
  
  validates_presence_of :departing, :arriving, :departing_seconds
  
  attr_accessor :departing_at
  attr_accessor :arriving_at
  
  named_scope :departing_when, lambda { |start_date| { :conditions => ['timetable_type_id = ? and departing_seconds > ?', TimetableDay.find_by_wday(start_date.wday).timetable_type_id, start_date.seconds_since_midnight], :order => 'departing_seconds' }}
  named_scope :departing_exactly_when, lambda { |start_date| { :conditions => ['timetable_type_id = ? and departing_seconds = ?', TimetableDay.find_by_wday(start_date.wday).timetable_type_id, start_date.seconds_since_midnight]}}
  named_scope :departing_from, lambda { |station| { :conditions => ['departing_id = ?', station] }}
  named_scope :arriving_to, lambda { |station| { :conditions => ['arriving_id = ?', station] }}
  named_scope :limit, lambda { |limit| { :limit => limit }}
  
  def self.logger
    RAILS_DEFAULT_LOGGER
  end

  def <=> (b)    
    (b and b.departing_at) ? (departing_at ? departing_at <=> b.departing_at : 1) : ( departing_at ? -1 : 0)
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

    if journeys.empty? && from.hour >= 21
      from = from.midnight + 1.day
      journeys = Journey.departing_from(departing).arriving_to(arriving).departing_when(from).limit(limit)
    end
  
    #transpose departing/arriving times
    journeys.each do |j|
      j.departing_at = from.midnight + j.departing_seconds
      j.arriving_at = from.midnight + j.arriving_seconds
    end    
    
    journeys
  end
  
  
  
end
