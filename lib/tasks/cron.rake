task :cron => :environment do
  Rake::Task["db:purge"].invoke
  Rake::Task["db:seed"].invoke
end