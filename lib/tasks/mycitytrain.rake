namespace :mycitytrain do
  namespace :db do
    desc "Destroys all journeys and stops older than today"
    task :purge => :environment do
	  	puts "Purging all journeys/stops before #{Time.zone.now.midnight}"
      older_than_today = ["departing_at < ?", Time.zone.now.midnight]
      Stop.destroy_all older_than_today
      Journey.destroy_all older_than_today
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

	    starting_time = Time.zone.now
	    puts "Start populate at #{starting_time}"

      sorted = from_to.uniq.sort {|a, b| a[0].name + a[1].name <=> b[0].name + b[1].name}
      sorted.each do |j|
	  	  print "Loading journey #{j[0].name} to #{j[1].name} "
	  	  print '(today '; Journey.today(j[0], j[1])
	  	  print 'tomorrow '; Journey.tomorrow(j[0], j[1])
	  	  if Time.zone.now.hour => 12
	  	    #we are running populate after midday, also load for the day after tomorrow
   	  	  print ' and the next day'
	  		  Journey.fetch_date(j[0], j[1], Time.zone.now.midnight + 2.day) 
  	    end
   	    puts ')'
   	    
	    end
	  
	    puts "Complete populate at #{Time.zone.now}, a duration of #{(Time.zone.now - starting_time).round} seconds."

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