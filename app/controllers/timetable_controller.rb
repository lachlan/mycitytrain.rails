class TimetableController < ApplicationController  
  caches_page :departing, :arriving 
  before_filter :find_journeys, :only => [:upcoming, :today, :tomorrow, :journey]
  
  def index
    expires_now

    @journeys = []
    favourites.each do |favourite|
      d = Station.find_by_code(favourite[0])
      a = Station.find_by_code(favourite[1])
      
      if d and a
        journey = Journey.upcoming(d, a).first || Journey.new(:departing => d, :arriving => a, :departing_at => nil)
        @journeys << journey if journey
      else
        logger.error("Attempt to access invalid station/s: '#{favourite[0]}', '#{favourite[1]}'") 
      end
    end

    # refresh the page when the next closest service departs
    min = @journeys.min.departing_at if @journeys.length > 0
    @refresh = (min - Time.zone.now).to_i.seconds if min
    
  end
  
  def add_favourite
    favourites << [params[:departing], params[:arriving]] unless favourites.find { |f| f[0] == params[:departing] and f[1] == params[:arriving]}        
    redirect_to :action => 'index'
  end
  
  def remove_favourite
    favourites.delete [params[:departing], params[:arriving]]
    redirect_to :action => 'index'
  end
  
  def departing
    expires_in 1.day
    @stations = Station.find_all
  end
  
  def arriving
    expires_in 1.day

    @departing = Station.find_by_code(params[:departing])
    if @departing
      @stations = Station.find_all
    else
      logger.error("Attempt to access invalid station/s: '#{params[:departing]}'") 
      redirect_to :action => 'index'
    end
  end
  
  
  def upcoming
	@journeys = Journey.upcoming @departing, @arriving
	@refresh = (@journeys[1].departing_at - Time.zone.now).to_i.seconds if @journeys and @journeys.length > 1
  end
  
  def today
	@journeys = Journey.today @departing, @arriving
	@refresh = end_of_the_day if @journeys and @journeys.length > 1
  end
  
  def tomorrow
	@journeys = Journey.tomorrow @departing, @arriving
	@refresh = end_of_the_day if @journeys and @journeys.length > 1
  end

  def journey
  	@departing_at = Time.zone.parse(params[:departing_at])
  	
  	if @departing_at  	
  	  Journey.load_stops(@departing, @arriving, @departing_at)	
  	  @journey = Journey.find_by_departing_id_and_arriving_id_and_departing_at(@departing, @arriving, @departing_at, :include => :stops)
    end
    
	unless @journey
      logger.error("Attempt to access invalid journey: '#{params[:departing]}' to '#{params[:arriving]}' at '#{params[:departing_at]}'") 
      redirect_to :action => 'index'
    end
  end
  
  private

  def find_journeys
  	@departing = Station.find_by_code(params[:departing])
  	@arriving = Station.find_by_code(params[:arriving])
  	unless @departing and @arriving
      logger.error("Attempt to access invalid station/s: '#{params[:departing]}', '#{params[:arriving]}'") 
      redirect_to :action => 'index'
    end
  	@favourite = favourites.find { |f| f[0] == params[:departing] and f[1] == params[:arriving]}  

  end
  	
  def end_of_the_day
    (Time.zone.now.midnight + 1.day - Time.zone.now).to_i.seconds
  end
  
end
