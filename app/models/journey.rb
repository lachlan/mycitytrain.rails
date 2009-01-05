class Journey < ActiveRecord::Base
  include Comparable
  belongs_to :departing, :class_name => 'Station'
  belongs_to :arriving, :class_name => 'Station'
  has_many :stops, :order => :position
  
  validates_presence_of :departing, :arriving, :departing_at

  named_scope :departing_before, lambda { |date| { :conditions => ['departing_at < ?', date], :order => 'departing_at' }}
  named_scope :departing_after, lambda { |date| { :conditions => ['departing_at > ?', date], :order => 'departing_at' }}
  named_scope :departing_between, lambda { |start_date, end_date| { :conditions => ['departing_at between ? and ?', start_date, end_date], :order => 'departing_at' }}
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
        if last_stop == stop.station.id
          changes << service
          service = []
        end
        service << stop
        last_stop = stop.station.id
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
    Time.zone = "Brisbane"
    now = Time.zone.now
    api_called = false
    journeys = []
    
    begin
      journeys = Journey.departing_from(d).arriving_to(a).departing_after(now).limit(10)
	
	    if (!journeys or journeys.length == 0) and !api_called
	      raise "No journeys found, try the Citytrain API"
	    end
	  rescue Exception
	    CitytrainAPI.journeys(d, a, now)
	    CitytrainAPI.journeys(d, a, now + 1.day)
	    api_called = true
	    retry
	  end
	  
	  journeys
  end
  
  def self.today(d, a)
    Time.zone = "Brisbane"
	  today = Time.zone.local(Time.zone.now.year, Time.zone.now.month, Time.zone.now.day)
    api_called = false
    journeys = []
    
    begin
      journeys = Journey.departing_from(d).arriving_to(a).departing_between(today, today + 1.day)
	
	    if (!journeys or journeys.length == 0) and !api_called
	      raise "No journeys found, try the Citytrain API"
	    end
	  rescue Exception
	    CitytrainAPI.journeys(d, a, today)
	    api_called = true
	    retry
	  end
	  
	  journeys
  end
  
  def self.tomorrow(d, a)
    Time.zone = "Brisbane"
	  tomorrow = Time.zone.local(Time.zone.now.year, Time.zone.now.month, Time.zone.now.day) + 1.day
    api_called = false
    journeys = []
    
    begin
      journeys = Journey.departing_from(d).arriving_to(a).departing_between(tomorrow, tomorrow + 1.day)
	
	    if (!journeys or journeys.length == 0) and !api_called
	      raise "No journeys found, try the Citytrain API"
	    end
	  rescue Exception
	    CitytrainAPI.journeys(d, a, tomorrow)
	    api_called = true
	    retry
	  end
	  
	  journeys
  end
  
end
