class FavouritesController < ApplicationController
    
  def index
    @favourites = []
    @stations = Station.find_all
    session[:favourites].each do |favourite|
      @favourites << Favourite.new(favourite[0], favourite[1])
    end
    @favourites = [nil,nil,nil] if @favourites.empty?
    render :layout => !request.xhr?  
  end

end
