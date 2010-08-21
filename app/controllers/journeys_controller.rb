class JourneysController < ApplicationController  
  before_filter :find_stations, :except => [:index, :favourites, :create]
  before_filter :find_favourites, :only => [:index, :favourites]
  
  protect_from_forgery :only => [:create, :update, :destroy] 
  @@journeys_limit = 5
  @@settings_limit = 7
  
  def index
  end
  
  def favourites
    render :layout => !request.xhr?
  end
  
  def create
    origins = params[:origin]
    destinations = params[:destination]
    
    @favourites = []
    cookie = []
    origins.sort.each { |item|
      key, value = item[0], item[1]
      unless key.empty? and value.empty?
        favourite = Favourite.new(value, destinations[key])
        @favourites << favourite
        cookie << [favourite.origin, favourite.destination]
      end
    }
    
    session[:favourites] = cookie
    redirect_to '/'
  end
  
  def list
    limit = params[:limit] || @@journeys_limit
    if params[:after]
      after = Time.zone.parse(params[:after])
      after = Time.zone.now if after < Time.zone.now # only return journeys that haven't departed yet
    else
      after = Time.zone.now
    end
    @journeys = Journey.departing_after @departing, @arriving, after, limit
    render :layout => !request.xhr?
  end

  # currently this doesn't work!
  # def show
  #   @journey = Journey.find_with_stops(@departing, @arriving, @departing_at) if @departing_at    
  #   unless @journey
  #     logger.error("Attempt to access invalid journey: '#{params[:departing]}' to '#{params[:arriving]}' at '#{params[:departing_at]}'") 
  #     redirect_to :action => 'index'
  #   end
  #   render :layout => !request.xhr?
  # end
  
  def about
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
  
  def find_favourites
    @settings = []
    @stations = Station.find_all    
    @@settings_limit.times do |i|
      s = session[:favourites][i] || []
      @settings << Favourite.new(s[0], s[1])
    end
    @favourites = @settings.reject { |f| f.empty? }
  end 
end
