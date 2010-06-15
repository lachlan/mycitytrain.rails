class JourneysController < ApplicationController  
  before_filter :find_stations, :except => [:index, :create]
  protect_from_forgery :only => [:create, :update, :destroy] 
  @@limit = 5
  
  def index
    @settings, @favourites = [], []
    @stations = Station.find_all    
    @@limit.times do |i|
      s = session[:favourites][i] || []
      favourite = Favourite.new(i, s[0], s[1])
      @settings << favourite
      @favourites << favourite if favourite.departing and favourite.arriving
    end
    render :layout => !request.xhr?
  end
  
  def create
    origins = params[:origin]
    destinations = params[:destination]
    
    @favourites = []
    cookie = []
    origins.each { |key, value|
      @favourites << Favourite.new(key.to_i, value, destinations[key])
      cookie << [value, destinations[key]] unless value.empty? or destinations[key].empty?
    }
    
    session[:favourites] = cookie
    redirect_to '/'
  end
  
  def list
    limit = params[:limit] || @@limit
    if params[:after]
      after = Time.zone.parse(params[:after])
      after = Time.zone.now if after < Time.zone.now # only return journeys that haven't departed yet
    else
      after = Time.zone.now
    end
    @journeys = Journey.departing_after @departing, @arriving, after, limit
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
