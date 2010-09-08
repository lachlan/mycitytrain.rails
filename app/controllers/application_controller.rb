class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :init, :www_redirect
  
  def init
    #ensure the the session favourites array has been initialised before use
    session[:favourites] ||= []
  end

  def www_redirect
    head :moved_permanently, :location => "http://mycitytrain.info/" if request.env['HTTP_HOST'] =~ /^www\./i
  end
end
