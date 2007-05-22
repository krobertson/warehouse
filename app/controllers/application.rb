# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  helper_method :current_repository, :logged_in?, :current_user, :admin?, :controller_path
  before_filter :check_for_repository
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

  def current_repository
    @current_repository ||= Warehouse.multiple_repositories ? subdomain_repository : default_repository
  end
  
  protected
    def access_denied(options = {})
      flash[:error] = options[:error] if options[:error]
      redirect_to options[:url] || root_path
      false
    end

    def repository_subdomain
      request.subdomains.first
    end
  
    def check_for_repository
      current_repository || access_denied
    end
    
    def default_repository
      Repository.find(:first)
    end
    
    def subdomain_repository
      !repository_subdomain.blank? && Repository.find_by_subdomain(repository_subdomain)
    end
end
