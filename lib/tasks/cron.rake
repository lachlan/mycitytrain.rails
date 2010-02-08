task :cron => :environment do
 Rake::Task["mycitytrain:db:populate"].invoke
 Rake::Task["mycitytrain:db:purge"].invoke
end