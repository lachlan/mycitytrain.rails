class Journey < ActiveRecord::Base
  include Comparable
  
  belongs_to :departing, :class_name => 'Station'
  belongs_to :arriving, :class_name => 'Station'
  has_many :stops, :order => :position
  
  validates_presence_of :departing, :arriving, :departing_at

  named_scope :departing_when, lambda { |start_date, end_date| 
    if start_date and end_date
      {:conditions => ['departing_at between ? and ?', start_date, end_date], :order => 'departing_at' }
    elsif start_date
      { :conditions => ['departing_at > ?', start_date], :order => 'departing_at' }
    elsif end_date  
      { :conditions => ['departing_at < ?', end_date], :order => 'departing_at' }
    else
      { :order => 'departing_at' } 
    end
  }
  
  named_scope :departing_from, lambda { |station| { :conditions => ['departing_id = ?', station] }}
  named_scope :arriving_to, lambda { |station| { :conditions => ['arriving_id = ?', station] }}
  named_scope :limit, lambda { |limit| { :limit => limit }}
  
  #Comparing the departing_at for two journeys
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
    changes << service if service and service.length > 0
  end
  
  def arriving_at
    if stops and stops.last
      stops.last.arriving_at
    else
      departing_at
    end
  end
  
  def self.upcoming(d, a)
    self.fetch_journeys(:departing => d, :arriving => a, :from => Time.zone.now, :limit => 10)
  end
  
  def self.today(d, a)
  	today = Time.zone.now.midnight 
    self.fetch_journeys(:departing => d, :arriving => a, :from => today, :to => today + 1.day)
  end
  
  def self.tomorrow(d, a)
  	tomorrow = Time.zone.now.tomorrow.midnight
    self.fetch_journeys(:departing => d, :arriving => a, :from => tomorrow, :to => tomorrow + 1.day)
  end
  
  def self.fetch_journeys(o)
  	departing, arriving, from, to, limit = o[:departing], o[:arriving], o[:from], o[:to], (o[:limit] || 9999)
	
  	journeys = Journey.departing_from(departing).arriving_to(arriving).departing_when(from, to).limit(limit)

    retries = 0
    while (retries < 10 and (!journeys or journeys.length == 0))
      0.upto(1) { |i| CitytrainAPI.journeys(departing, arriving, Time.zone.now.midnight + i.day) }
      journeys = Journey.departing_from(departing).arriving_to(arriving).departing_when(from, to).limit(limit)
      retries += 1
      sleep 3 if retries > 1 #Sleep in between attempts (3 seconds)
    end
	  		
    journeys
  end
  
  alias base_stops stops
  def stops
    s = base_stops
    retries = 0
  	while (retries < 10 and s.empty?)
  		CitytrainAPI.stops self
  		reload
  		s = base_stops
      retries += 1
	    sleep 3 if retries > 1 #Sleep in between attempts (3 seconds)
  	end
  	s
  end
  
end
