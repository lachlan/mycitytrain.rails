ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'timetable'

  map.sitemap 'sitemap.xml' , :controller => 'sitemap' , :action => 'sitemap'

  map.connect 'favourite', :controller => 'timetable', :action => 'favourite'
  map.connect 'favourites', :controller => 'timetable', :action => 'add_favourite'
  map.connect 'about', :controller => 'timetable', :action => 'about'

  map.with_options :controller => 'timetable' do |t|
    t.connect 'timetable', :action => 'departing'
    t.connect 'timetable/:departing', :action => 'arriving'
    t.connect 'timetable/:departing/:arriving/upcoming', :action => 'upcoming'
    t.connect 'timetable/:departing/:arriving/today', :action => 'today'
    t.connect 'timetable/:departing/:arriving/tomorrow', :action => 'tomorrow'
    t.connect 'timetable/:departing/:arriving/favourite/add', :action => 'add_favourite'
    t.connect 'timetable/:departing/:arriving/favourite/remove', :action => 'remove_favourite'
    t.connect 'timetable/:departing/:arriving/:departing_at', :action => 'journey'
  end
  
end
