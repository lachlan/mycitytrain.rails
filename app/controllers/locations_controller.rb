class LocationsController < ApplicationController

  def index
    @locations = Location.all
    render :json => @locations.map { |location| location.name }
  end
  
end
