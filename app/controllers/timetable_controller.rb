class TimetableController < ApplicationController  
  caches_page :departing, :arriving 
  
  def index
    expires_now
        
    threads = []
    favourites.each do |favourite|
      # TODO: this is vulnerable to a denial of service attack, need to limit how many threads get spun up
      # spin up a thread for each favourite to find the next journey, hopefully reducing the response time of the action
      threads << Thread.new(favourite) do |f| 
        d, a = Station.find_by_code(f[0]), Station.find_by_code(f[1])
        journey = nil
        
        if d and a
          journey = Journey.upcoming(d, a).first if d and a
          journey ||= Journey.new(:departing => d, :arriving => a, :departing_at => nil)
        else
          logger.error("Attempt to access invalid station/s: '#{favourite[0]}', '#{favourite[1]}'")
        end
        
        journey
      end
    end
    
    # wait for threads to finish and gather their return values, then throw away nil journeys
    @journeys = threads.map { |thread| thread.value }
    @journeys.reject! { |j| j.nil? }
    
    # refresh the page when the next closest service departs
    min = @journeys.min.departing_at unless @journeys.empty?
    @refresh = (min - Time.zone.now).to_i.seconds if min
  end
  
  def favourite
    favourites << [params[:departing], params[:arriving]] unless favourites.find { |f| f[0] == params[:departing] and f[1] == params[:arriving]}        
    redirect_to :action => 'index'
  end
  
  def destroy_favourites
    session[:favourites] = []
    redirect_to :action => 'index'
    return
  end
  
  def departing
    expires_in 1.day
    @stations = Station.find_all
  end
  
  def arriving
    expires_in 1.day

    @departing = Station.find_by_code(params[:departing])
    
    if @departing
      @stations = Station.find_all
    else
      logger.error("Attempt to access invalid station/s: '#{params[:departing]}'") 
      redirect_to :action => 'index'
    end
  end
  
  def upcoming
  	@departing = Station.find_by_code(params[:departing])
  	@arriving = Station.find_by_code(params[:arriving])

    if @departing and @arriving
      @journeys = Journey.upcoming @departing, @arriving
	
	    if @journeys and @journeys.length > 1
	      @refresh = (@journeys[1].departing_at - Time.zone.now).to_i.seconds
	      expires_in @refresh
	    else
	      expires_now
	    end
    else
      logger.error("Attempt to access invalid station/s: '#{params[:departing]}', '#{params[:arriving]}'") 
      redirect_to :action => 'index'
    end
  end
  
  def today
  	@departing = Station.find_by_code(params[:departing])
  	@arriving = Station.find_by_code(params[:arriving])

    if @departing and @arriving
      @journeys = Journey.today @departing, @arriving
	
      if @journeys and @journeys.length > 1
	      @refresh = end_of_the_day 
	      expires_in @refresh
      else
        expires_now
      end

    else
      logger.error("Attempt to access invalid station/s: '#{params[:departing]}', '#{params[:arriving]}'") 
      redirect_to :action => 'index'
    end
  end
  
  def tomorrow
  	@departing = Station.find_by_code(params[:departing])
  	@arriving = Station.find_by_code(params[:arriving])

    if @departing and @arriving
      @journeys = Journey.tomorrow @departing, @arriving
	
      if @journeys and @journeys.length > 1
	      @refresh = end_of_the_day 
	      expires_in @refresh
      else
        expires_now
      end

    else
      logger.error("Attempt to access invalid station/s: '#{params[:departing]}', '#{params[:arriving]}'") 
      redirect_to :action => 'index'
    end
  end

  def journey
    expires_in 1.year
    
  	departing = Station.find_by_code(params[:departing])
  	arriving = Station.find_by_code(params[:arriving])
  	departing_at = Time.zone.parse(params[:departing_at])
  	
  	if departing and arriving and departing_at  	
  	  @journey = Journey.find_by_departing_id_and_arriving_id_and_departing_at(departing, arriving, departing_at, :include => :stops)
    else
      logger.error("Attempt to access invalid journey: '#{params[:departing]}' to '#{params[:arriving]}' at '#{params[:departing_at]}'") 
      redirect_to :action => 'index'
    end
  end
  
  private
  
  def end_of_the_day(date = Time.zone.now)
    next_day = date + 1.day
    next_day = Time.zone.local(next_day.year, next_day.month, next_day.day)
    
    (next_day - date).to_i.seconds
  end
  
end
