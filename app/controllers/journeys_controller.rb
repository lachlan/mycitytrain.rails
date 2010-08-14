class JourneysController < ApplicationController  
  before_filter :find_stations, :except => [:index, :create]
  protect_from_forgery :only => [:create, :update, :destroy] 
  @@limit = 5
  
  def index
    @settings, @favourites = [], []
    @stations = Station.find_all    
    @@limit.times do |i|
      s = session[:favourites][i] || []
      if @settings.include? [s[1], s[0]]
        @settings << []
      else
        @settings << [s[0], s[1]]
      end
    end
    @settings = @settings.map{|i| Favourite.new i[0], i[1]}
    @favourites = @settings.select{|i| i.departing and i.arriving}
    render :layout => !request.xhr?
  end
  
  def create
    origins = params[:origin]
    destinations = params[:destination]
    
    @favourites = []
    cookie = []
    origins.each_with_index { |value, index|
      @favourites << Favourite.new(value, destinations[index])
      cookie << [value, destinations[index]] unless value.empty? or destinations[index].empty? or cookie.include? [destinations[index], value]
    }
    
    session[:favourites] = cookie.uniq
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
end
