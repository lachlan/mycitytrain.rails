# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)
puts "== db:seed task started"

location_count = Location.refresh
puts "refreshed #{location_count} network location/s"

distinct_accessed_journeys = []
Location.all.each do |location|
  if location.journeys.count > 0
    distinct_accessed_journeys += location.journeys.map{ |journey| [journey.origin, journey.destination] }.uniq
  end
end
begin
  distinct_accessed_journeys.uniq!.each do |tuple|
    origin, destination, count = tuple[0], tuple[1], 0
  
    latest_journey = Journey.latest(origin, destination)
    latest_date = latest_journey.depart_at unless latest_journey.nil?
    latest_date = Time.zone.now if latest_date.nil? or latest_date < Time.zone.now # don't worry about already departed journeys
    range = latest_date..(Time.zone.now.midnight + 2.days)
  
    if (range.first < range.last)
      begin  
        count += Journey.refresh origin, destination
        latest_date = Journey.latest(origin, destination).depart_at
      end until latest_date > range.last
    end
    puts "cached #{count} journey/s: #{range} #{origin.name} to #{destination.name}"
  end
rescue => detail
 puts "[ERROR] #{detail}"
end
puts "== db:seed task completed: refreshed #{location_count} network locations, and cached #{distinct_accessed_journeys.count} previously accessed journey/s from TransLink"