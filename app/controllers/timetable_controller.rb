class TimetableController < ApplicationController  
  before_filter :find_stations, :only => [:favourite, :upcoming, :journey]
  protect_from_forgery :only => [:create, :update, :destroy] 
  
  def index
    expires_now
    @favourites = []
    session[:favourites].each do |favourite|
      @favourites << {:departing => Station.find_by_code(favourite[0]), 
                      :arriving => Station.find_by_code(favourite[1]), 
                      :journeys => Journey.upcoming(Station.find_by_code(favourite[0]), Station.find_by_code(favourite[1]), 5),
                      :return_journeys => Journey.upcoming(Station.find_by_code(favourite[1]), Station.find_by_code(favourite[0]), 5)}
    end
    @favourites = [{}] unless @favourites.length > 0
    @stations = Station.find_all
    
    # refresh the page when the next closest service departs
    #min = @journeys.min.departing_at if @journeys.length > 0
    #@refresh = (min - Time.zone.now).to_i.seconds if min
  end
  
  def favourite
    @idx = params[:idx].to_i
    @stations = Station.find_all
    session[:favourites][@idx] = [@departing.code, @arriving.code]
    @favourite = {:departing => @departing,
                  :arriving => @arriving,
                  :journeys => Journey.upcoming(@departing, @arriving, 5),
                  :return_journeys => Journey.upcoming(@departing, @arriving, 5)}

    render :layout => false
  end

  def upcoming
    @journeys = Journey.upcoming @departing, @arriving
    @refresh = (@journeys[1].departing_at - Time.zone.now).to_i.seconds if @journeys and @journeys.length > 1
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
    render :layout => false
  end
  
  private

  def find_stations
  	@departing = Station.find params[:departing]
  	@arriving = Station.find params[:arriving]  	
  	if @departing and @arriving
      @favourite_verb = session[:favourites].include?([@departing.code, @arriving.code]) ? 'remove' : 'add' 
  	else
      logger.error("Attempt to access invalid station/s: '#{params[:departing]}', '#{params[:arriving]}'") 
      redirect_to :action => 'index'
    end
  end
  	
  def end_of_the_day
    (Time.zone.now.midnight + 1.day - Time.zone.now).to_i.seconds
  end
  
end
