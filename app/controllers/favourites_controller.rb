class FavouritesController < ApplicationController
  @@limit = 7 # number of favourites allowed per user
  
  # GET /favourites
  def index
    @favourites = []  
    @@limit.times do |i|
      s = session[:favourites][i] || []
      @favourites << Favourite.new(s[0], s[1])
    end
    respond_to do |format|
      format.html { render :layout => !request.xhr? }
    end
  end
  
  # POST /favourites  
  def create
    favourites, cookie = [], []
    origins = params[:origin]
    destinations = params[:destination]

    origins.sort.each do |item|
      key, value = item[0], item[1]
      unless key.empty? and value.empty?
        favourites << Favourite.new(value, destinations[key])
        cookie << [favourites.last.origin.name, favourites.last.destination.name]
      end
    end
    session[:favourites] = cookie
    render :layout => !request.xhr?
  end
  
end
