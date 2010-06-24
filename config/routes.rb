ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'journeys'
  
  map.with_options :controller => 'journeys' do |t|
    t.connect '/settings', :action => 'create'
    t.connect '/:departing/:arriving', :action => 'list'
    # show not currently working
    # t.connect '/:departing/:arriving/:departing_at', :action => 'show'
  end
end