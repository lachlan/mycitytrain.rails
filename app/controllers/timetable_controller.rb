class TimetableController < ApplicationController  
  # TODO: implement cache sweeping
  #caches_page :departing, :arriving
  
  def index
    expires_now
        
    Time.zone = "Brisbane"
    @journeys = []
    favourites.each do |favourite|
      d = Station.find_by_code(favourite[0])
      a = Station.find_by_code(favourite[1])
      
      if d and a
        journey = Journey.upcoming(d, a).first
        journey ||= Journey.new(:departing => d, :arriving => a, :departing_at => nil)
        @journeys << journey if journey
      else
        logger.error("Attempt to access invalid station/s: '#{favourite[0]}', '#{favourite[1]}'") 
      end
    end
    
    # refresh the page when the next closest service departs
    min = @journeys.min { |a, b| a.departing_at <=> b.departing_at }
    @refresh = (min.departing_at - Time.zone.now).to_i.seconds if min
    
    respond_to do |format|
      format.html 
      format.xml  { render :xml => @journeys }
    end
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
    
    respond_to do |format|
      format.html 
      format.xml  { render :xml => @stations  }
    end
  end
  
  def arriving
    expires_in 1.day

    @departing = Station.find_by_code(params[:departing])
    
    if @departing
      @stations = Station.find_all
      respond_to do |format|
        format.html 
        format.xml  { render :xml => @stations  }
      end      
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
	    
      respond_to do |format|
        format.html 
        format.xml  { render :xml => @journeys }
      end
    else
      logger.error("Attempt to access invalid station/s: '#{params[:departing]}', '#{params[:arriving]}'") 
      redirect_to :action => 'index'
    end
  end
  
  def today
    @refresh = end_of_the_day 
    expires_in @refresh
        
  	@departing = Station.find_by_code(params[:departing])
  	@arriving = Station.find_by_code(params[:arriving])

    if @departing and @arriving
      @journeys = Journey.today @departing, @arriving
	
      respond_to do |format|
        format.html 
        format.xml  { render :xml => @journeys }
      end
    else
      logger.error("Attempt to access invalid station/s: '#{params[:departing]}', '#{params[:arriving]}'") 
      redirect_to :action => 'index'
    end
  end
  
  def tomorrow
    @refresh = end_of_the_day
    expires_in @refresh
    
  	@departing = Station.find_by_code(params[:departing])
  	@arriving = Station.find_by_code(params[:arriving])

    if @departing and @arriving
      @journeys = Journey.tomorrow @departing, @arriving
	
      respond_to do |format|
        format.html 
        format.xml  { render :xml => @journeys }
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
  	
      respond_to do |format|
        format.html 
        format.xml  { render :xml => @stops }
      end
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
