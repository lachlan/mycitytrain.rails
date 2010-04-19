namespace :translink do

  desc "Loads stations from Translink API"
  task :populate_stations => :environment do

    starting_time = Time.zone.now
    puts "Start populate at #{starting_time}"

    # Load stations
    TranslinkAPI.stations

    puts "Complete populate at #{Time.zone.now}, a duration of #{(Time.zone.now - starting_time).round} seconds."

  end

  desc "Load station aliases from the station table"
  task :populate_aliases => :environment do
    
    TlStation.all.each do |station|
      # For airport stations, add an extra alias
      if station.name =~ /(\w+)\s+(airport)/i
        Alias.find_or_create_by_name(:name => "#{$2.strip} - #{$1.strip}", :station_id => station.id)
      end
      
      if station.name =~ /(.+)\((.+)\)/
        # Two aliases for stations which have two names associated with them
        Alias.find_or_create_by_name(:name => "#{$1.strip}", :station_id => station.id)
        Alias.find_or_create_by_name(:name => "#{$2.strip}", :station_id => station.id)
      else
        Alias.find_or_create_by_name(:name => station.name, :station_id => station.id)
      end
      
    end
    
  end
  

  # TlStation.find_or_create_by_code(:name => o.content.strip, :code => o[:value].strip)

end