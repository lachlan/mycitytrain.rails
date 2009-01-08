namespace :mycitytrain do
  namespace :db do
    desc "Destroys all journeys and stops older than today"
    task :purge => :environment do
      condition = ["departing_at < ?", Time.zone.now.yesterday.midnight]
      Stop.destroy_all condition
      Journey.destroy_all condition
    end
    
    desc "Loads stations, journeys and stops from Citytrain API"
    task :populate => :environment do
      # Load stations
      CitytrainAPI.stations
      
      # TODO: Load future journeys for any journeys that already exist
      # TODO: Load future stops for any journeys that already exist
    end
    
  end
end