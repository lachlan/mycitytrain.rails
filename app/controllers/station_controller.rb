class StationController < ApplicationController
  def index
    @stations = Station.all.map{|s|s.name}
    
    respond_to do |format|
      format.js { render :json => @stations }
    end
  end
    
end
