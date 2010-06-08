namespace :db do
  desc "Load seed data for TimetableType and TimetableDay."
  task :seed => :environment do
    TimetableDay.create(:timetable_type => TimetableType.create(:name => 'Sun'), :wday => 0)
    (1..4).each {|wday| TimetableDay.create(:timetable_type => TimetableType.find_or_create_by_name(:name => 'Mon-Thu'), :wday => wday)}
    TimetableDay.create(:timetable_type => TimetableType.create(:name => 'Fri'), :wday => 5)
    TimetableDay.create(:timetable_type => TimetableType.create(:name => 'Sat'), :wday => 6)
    
    CitytrainAPI.stations
  end

  desc "This drops the db, builds the db, and seeds the data."
  task :reseed => [:environment, 'db:reset', 'db:seed']
end
