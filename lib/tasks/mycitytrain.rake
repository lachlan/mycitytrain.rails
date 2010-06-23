namespace :mycitytrain do
  namespace :db do
    desc "Destroys all journeys and stops older than today"
    task :purge => :environment do
      puts "Purging all journeys/stops before #{Time.zone.now.midnight}"
      older_than_today = ["departing_at < ?", Time.zone.now.midnight]
      Stop.destroy_all older_than_today
      Journey.destroy_all older_than_today
      
      puts "Purging all historic journeys older than #{30.days.ago}"
      HistoricJourney.destroy_all(["created_at < ?", 30.days.ago])
    end
    
    desc "Loads stations, journeys from Citytrain API"
    task :populate => :environment do
      # Load stations
      CitytrainAPI.stations
      
      # fetch any journeys that have been looked at
      historic_journeys = HistoricJourney.all.map {|h| [h.departing, h.arriving] }.uniq
      
      starting_time = Time.zone.now
      puts "Start populate at #{starting_time}"

      historic_journeys.sort {|a, b| a[0].name + a[1].name <=> b[0].name + b[1].name}.each do |j|
        puts "Loading journey #{j[0].name} to #{j[1].name} "
        Journey.today(j[0], j[1])
      end
    
      puts "Complete populate at #{Time.zone.now}, a duration of #{(Time.zone.now - starting_time).round} seconds, #{historic_journeys.length} journeys loaded."

    end
    
  end
end