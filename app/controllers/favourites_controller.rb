class FavouritesController < ApplicationController  
  @@limit = 3
  
  def index
    @favourites = []
    @stations = Station.find_all
    @count = @@limit

    @count.times do |i|
      favourite = session[:favourites][i] || []
      @favourites << Favourite.new(i, favourite[0], favourite[1])
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

end
