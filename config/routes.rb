ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'journeys'
  map.resources :settings, :only => [:index, :create]
  
  map.with_options :controller => 'journeys' do |t|
    t.connect '/about', :action => 'about'
    t.connect '/:departing/:arriving', :action => 'list'
    t.connect '/:departing/:arriving/:departing_at', :action => 'show'
  end
end