class JourneysController < ApplicationController  
  @@limit = 5 # number of journeys returned by default

  def index
    @origin = Location.search(params[:origin])
    @destination = Location.search(params[:destination])
    if @origin.nil?
      render :text => "Invalid location: #{params[:origin]}"
    elsif @destination.nil?
      render :text => "Invalid location: #{params[:destination]}"
    else
      limit = params[:limit] || @@limit
      after = (Time.zone.parse(params[:after]) if params[:after]) || Time.zone.now

      @journeys = Journey.after @origin, @destination, after, limit

      if @journeys.empty? and request.xhr?
        render :text => "No services found"
      else    
        respond_to do |format|
          format.html { render :layout => !request.xhr? }
          format.json { render :json => @journeys.to_json(:include => {:origin => {:only => :name}, :destination => {:only => :name}}, :only => [:depart_at, :arrive_at]) }
        end
      end
    end
  end
end