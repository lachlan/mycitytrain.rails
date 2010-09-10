namespace :db do
  desc 'Purges all journeys older than today, to keep the database light'
  task :purge => :environment do
    count = Journey.delete_all(['depart_at < ?', Time.zone.now.midnight])
    puts 'Purged ' + count.to_s + ' journey/s'
  end
end