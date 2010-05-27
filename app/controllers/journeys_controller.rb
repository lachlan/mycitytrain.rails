class JourneysController < ApplicationController  
  before_filter :find_stations, :except => :index
  protect_from_forgery :only => [:create, :update, :destroy] 
  @@limit = 5
  
  def index
    @favourites = session[:favourites].map do |f|
      Favourite.new(f[0], f[1])
    end
    @favourites = [] if @favourites.empty?
    @stations = Station.find_all
  end
  
  def departing_after
    @journeys = Journey.departing_after @departing, @arriving, @departing_at, @@limit
    render :layout => !request.xhr?
  end

  def show
  	if @departing_at  	
  	  Journey.load_stops(@departing, @arriving, @departing_at)	
  	  @journey = Journey.find_by_departing_id_and_arriving_id_and_departing_at(@departing, @arriving, @departing_at, :include => :stops)
    end
	  unless @journey
      logger.error("Attempt to access invalid journey: '#{params[:departing]}' to '#{params[:arriving]}' at '#{params[:departing_at]}'") 
      redirect_to :action => 'index'
    end
    render :layout => !request.xhr?
  end
  
  private
  def find_stations
  	@departing = Station.find params[:departing]
  	@arriving = Station.find params[:arriving] 
  	@departing_at = Time.zone.parse(params[:departing_at]) if params[:departing_at] 	
  	unless @departing and @arriving
      logger.error("Attempt to access invalid station/s: '#{params[:departing]}', '#{params[:arriving]}'") 
      redirect_to :action => 'index'
    end
  end
end
