namespace :mycitytrain do
  namespace :db do
    desc "Destroys all journeys and stops older than today"
    task :purge => :environment do
      condition = ["departing_at < ?", Time.zone.now.midnight]
      Stop.destroy_all condition
      Journey.destroy_all condition
    end
    
    desc "Loads stations, journeys and stops from Citytrain API"
    task :populate => :environment do
      # Load stations
      CitytrainAPI.stations
      
      # Load future journeys for any journeys that already exist
      from_to = []
      past_journeys = Journey.departing_when(nil, Time.zone.now.midnight)
      past_journeys.each do |j|
        from_to << [j.departing, j.arriving]
  	  end
	  
  	  from_to.uniq.each do |j|
  	  	puts "Loading journey #{j[0].name} to #{j[1].name}"
    		Journey.today(j[0], j[1])
    		Journey.tomorrow(j[0], j[1])
  	  end    

  	  # Load stops for the new journeys
=begin 
  	  #Taking too long to include the population of stops	  
  	  unless journeys.empty?
  	  	journeys.each do |j|
        	  puts "Loading stops for #{j.departing.name} to #{j.arriving.name} at #{j.departing_at}"
  	  	  j.stops
  	  	end  
  	  end    
=end
    end
    
  end
end