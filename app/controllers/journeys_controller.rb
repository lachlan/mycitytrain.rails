class JourneysController < ApplicationController  
  @@limit = 5 # number of journeys returned by default

  def index
    @origin = Location.find params[:origin]
    @destination = Location.find params[:destination]
    
    limit = params[:limit] || @@limit
    after = (Time.zone.parse(params[:after]) if params[:after]) || Time.zone.now

    @journeys = Journey.after @origin, @destination, after, limit
    @latest = Journey.latest @origin, @destination if @journeys.nil? or @journeys.empty?
    
    respond_to do |format|
      format.html { render :layout => !request.xhr? }
      format.json { render :json => @journeys.to_json(:include => {:origin => {:only => :name}, :destination => {:only => :name}}, :only => [:depart_at, :arrive_at]) }
    end
    
  end  
  
end
