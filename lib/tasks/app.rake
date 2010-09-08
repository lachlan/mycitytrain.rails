namespace :app do
  namespace :db do
    desc 'Purges all journeys older than today, to keep the database light'
    task :purge => :environment do
      count = Journey.delete_all(['depart_at < ?', Time.zone.now.midnight])
      puts 'Purged ' + count.to_s + ' journey/s'
    end

    # TODO...
    # desc 'Seed the database with network locations and timetabled services for previously accessed journeys'
    # task :seed => :environment do
    #   range = Date.tomorrow..(Date.tomorrow + 1.days)
    #   count = Location.refresh
    #   puts 'Refreshed ' + count.to_s + ' network location/s'
    #   distinct_accessed_journeys = []
    #   Location.all.each do |location|
    #     if location.journeys.count > 0
    #       distinct_accessed_journeys += location.journeys.map{ |journey| [journey.origin, journey.destination] }.uniq
    #     end
    #   end
    #   distinct_accessed_journeys.uniq!.each do |tuple|
    #     origin, destination = tuple[0], tuple[1]
    #     count = Journey.refresh tuple[0], tuple[1], range
    #     puts 'Cached ' + count.to_s + ' journey/s: ' + range.to_s + ' ' + origin.name + ' to ' + destination.name
    #   end      
    #   puts 'Refreshed all network locations, and cached ' + distinct_accessed_journeys.count.to_s + ' previously accessed journey/s from TransLink'
    # end
  end
end