# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  helper_method :current_repository, :logged_in?, :current_user, :admin?, :controller_path
  
  # expiring_attr_reader :controller_path, %([controller_name, action_name] * '/')
  
  #before_filter { |c| c.current_repository.sync_revisions }

  def logged_in?
    current_user != :false
  end
  
  def current_user
    @current_user ||= (session[:user_id] && User.find_by_id(session[:user_id])) || :false
  end
  
  def admin?
    logged_in? && current_user.admin?
  end

  def access_denied(options = {})
    flash[:error] = options[:error]
    redirect_to options[:url] || root_path
    false
  end

  def current_repository
    @current_repository ||= Repository.find(:first)
  end
end
