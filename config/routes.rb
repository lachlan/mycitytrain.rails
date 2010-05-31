ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'journeys'
  map.resources :settings
  map.resources :journeys
  map.sitemap 'sitemap.xml' , :controller => 'sitemap'
  
  map.with_options :controller => 'journeys' do |t|
    t.connect '/about', :action => 'about'
    t.connect '/:departing/:arriving/:departing_at', :action => 'show'
    t.connect '/:departing/:arriving/:departing_at/after', :action => 'departing_after'
  end
end