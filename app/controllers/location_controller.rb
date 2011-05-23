class LocationController < ApplicationController
  def index
    @locations = Location.all
    expires_in 1.week
    render :json => @locations.map { |location| location.name }
  end
end
