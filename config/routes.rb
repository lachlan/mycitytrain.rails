ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'timetable'

  map.connect 'about', :controller => 'timetable', :action => 'about'
  map.connect ':controller', :action => 'departing'
  map.connect ':controller/favourites/destroy', :action => 'destroy_favourites'
  map.connect ':controller/:departing', :action => 'arriving'
  map.connect ':controller/:departing/:arriving/upcoming', :action => 'upcoming'
  map.connect ':controller/:departing/:arriving/today', :action => 'today'
  map.connect ':controller/:departing/:arriving/tomorrow', :action => 'tomorrow'
  map.connect ':controller/:departing/:arriving/favourite', :action => 'favourite'
  map.connect ':controller/:departing/:arriving/:departing_at', :action => 'journey'
end
