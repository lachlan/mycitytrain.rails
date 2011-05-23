class JourneyController < ApplicationController
  @@limit = 5 # number of journeys returned by default

  def index
    @origin = Location.search(params[:origin])
    @destination = Location.search(params[:destination])
    
    if @origin.nil?
      render :text => "Unknown location: #{params[:origin]}", :status => :not_found
    elsif @destination.nil?
      render :text => "Unknown location: #{params[:destination]}", :status => :not_found
    else
      limit = params[:limit] || @@limit
      after = (Time.zone.parse(params[:after]) if params[:after]) || Time.zone.now

      @journeys = Journey.after @origin, @destination, after, limit

      if @journeys.empty?
        render :text => "No services found", :status => :not_found
      else
        expires_in (@journeys.first.depart_at - Time.now) - 1.minute
        render :json => @journeys
      end
    end
  end
end
