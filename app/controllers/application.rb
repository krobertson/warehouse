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

  def repository_member?
    return nil unless current_repository
    return nil unless logged_in? || current_repository.public?
    current_repository.member?(current_user, repository_path)
  end

  def repository_admin?
    return nil unless current_repository
    return nil unless logged_in? || current_repository.public?
    current_repository.admin?(current_user)
  end

  def current_repository
    @current_repository ||= Warehouse.multiple_repositories ? subdomain_repository : default_repository
  end
  
  def repository_path
  end
  
  protected
    def repository_member_required
      repository_member? || access_denied(:error => "You must be a member of this repository to visit this page.")
    end
    
    # specifies a controller action where a repository admin is required.
    def repository_admin_required
      repository_admin? || access_denied(:error => "You must be an administrator for this repository to visit this page.")
    end
    
    # specifies a controller action that only warehouse administrators are allowed
    def admin_required
      admin? || access_denied(:error => "You must be an administrator to visit this page.")
    end

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
