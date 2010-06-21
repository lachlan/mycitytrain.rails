class JourneysController < ApplicationController  
  before_filter :find_stations, :except => [:index, :about, :favourites]
  protect_from_forgery :only => [:create, :update, :destroy] 
  @@limit = 5
  
  def index
    render :layout => !request.xhr?
  end
  
  def favourites
    i = 0
    @favourites = session[:favourites].map do |f|
      Favourite.new(i+=1, f[0], f[1])
    end
    @favourites = [] if @favourites.empty?
    render :layout => !request.xhr?
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
    @journey = Journey.find_with_stops(@departing, @arriving, @departing_at) if @departing_at    
    unless @journey
      logger.error("Attempt to access invalid journey: '#{params[:departing]}' to '#{params[:arriving]}' at '#{params[:departing_at]}'") 
      redirect_to :action => 'index'
    end
    render :layout => !request.xhr?
  end
  
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
