task :cron => :environment do
  Rake::Task["db:seed"].invoke
  Rake::Task["db:purge"].invoke
end