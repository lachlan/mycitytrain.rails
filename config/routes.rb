ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'timetable'
  
  map.sitemap 'sitemap.xml' , :controller => 'sitemap' , :action => 'sitemap'
  
  map.with_options :controller => 'timetable' do |t|
    t.connect 'favourite', :action => 'favourite'
    t.connect 'about', :action => 'about'
    t.connect 'timetable/:departing/:arriving/upcoming', :action => 'upcoming'
    t.connect 'timetable/:departing/:arriving/:departing_at', :action => 'journey'
  end
end
