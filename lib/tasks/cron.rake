task :cron => :environment do
 Rake::Task["app:db:purge"].invoke
end