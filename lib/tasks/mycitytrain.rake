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
  end
end