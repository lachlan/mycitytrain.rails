task :cron => :environment do
 Rake::Task["mycitytrain:db:populate"].invoke
end