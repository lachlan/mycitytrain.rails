namespace :db do
  desc 'Purges all departed journeys to keep the database light'
  task :purge => :environment do
    count = Journey.delete_all(['depart_at < ?', (Time.zone.now - 1.minute)])
    puts 'Purged ' + count.to_s + ' journey/s'
  end
end