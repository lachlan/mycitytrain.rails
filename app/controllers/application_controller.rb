# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  before_filter :init, :www_redirect

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '7b6faab24f6e2db67b93827b62e75be7'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
  
  
  def init
    #ensure the the session favourites array has been initialised before use
    session[:favourites] ||= []
  end

  def www_redirect
    head :moved_permanently, :location => "http://mycitytrain.info/" if request.env['HTTP_HOST'] =~ /^www\./i
  end
  
end
