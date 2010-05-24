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
    changes << service if service and !service.empty?
  end
  
  def self.upcoming(d, a, limit = 10)
    #Record when upcoming journeys are being requested.  Only put it in the upcoming, as today/tommorrow are used during rake populate task
    HistoricJourney.create :departing => d, :arriving =>a
    
    self.fetch_journeys(:departing => d, :arriving => a, :from => Time.zone.now, :limit => limit)
  end
  
  def self.today(d, a)
  	today = Time.zone.now.midnight 
    fetch_date(d, a, today)
  end
  
  def self.tomorrow(d, a)
  	tomorrow = Time.zone.now.tomorrow.midnight
    fetch_date(d, a, tomorrow)
  end
  
  def self.fetch_date(d, a, w)
    self.fetch_journeys(:departing => d, :arriving => a, :from => w, :to => w + 1.day)
  end
  	
  def self.fetch_journeys(o)
    departing, arriving, from, to, limit = o[:departing], o[:arriving], o[:from], o[:to], (o[:limit] || 9999)	
  	journeys = Journey.departing_from(departing).arriving_to(arriving).departing_when(from, to).limit(limit)
	
  	if journeys.empty?
  	  0.upto(1) do |i|
    	  retries = 0
  			begin
  			  CitytrainAPI.journeys departing, arriving, Time.zone.now.midnight + i.day
  			rescue Exception
  			  retries += 1; sleep 3 #Sleep in between attempts (3 seconds)
  				retry if retries < 10
  				raise
  			end
  		end
      journeys = Journey.departing_from(departing).arriving_to(arriving).departing_when(from, to).limit(limit)
  	end
    journeys
  end
  
  #Populate stops if they don't exist in the database
  def self.load_stops(departing, arriving, departing_at)
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
