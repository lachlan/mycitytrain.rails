class JourneysController < ApplicationController  
  @@limit = 5 # number of journeys returned by default

  def index
    @origin = Location.find params[:origin]
    @destination = Location.find params[:destination]
    
    limit = params[:limit] || @@limit
    if params[:after]
      after = Time.zone.parse(params[:after])
      after = Time.zone.now if after.nil? or after < Time.zone.now # only return journeys that haven't departed yet
    else
      after = Time.zone.now
    end

    @journeys = Journey.after @origin, @destination, after, limit
    @latest = Journey.latest @origin, @destination if @journeys.nil? or @journeys.empty?
    
    respond_to do |format|
      format.html { render :layout => !request.xhr? }
      format.json { render :json => @journeys.to_json(:include => {:origin => {:only => :name}, :destination => {:only => :name}}, :only => [:depart_at, :arrive_at]) }
    end
    
  end  
  
end
