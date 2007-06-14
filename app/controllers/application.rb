# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  helper_method :current_repository, :logged_in?, :current_user, :admin?, :controller_path, :repository_admin?, :repository_member?
  before_filter :check_for_repository
  #before_filter { |c| c.current_repository.sync_revisions }

  expiring_attr_reader :current_user,       :retrieve_current_user
  expiring_attr_reader :repository_member?, :retrieve_repository_member
  expiring_attr_reader :repository_admin?,  :retrieve_repository_admin

  def logged_in?
    !!current_user
  end
  
  def admin?
    logged_in? && current_user.admin?
  end

  def current_repository
    @current_repository ||= Warehouse.multiple_repositories ? subdomain_repository : default_repository
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

    def login_required
      logged_in? || access_denied(:error => "You must be logged in to edit a profile.")
    end

    def access_denied(options = {})
      @error = options[:error] || "A login is required to visit this page."
      render :template => 'layouts/error'
      false
    end

    def repository_path
      return nil if @node.nil?
      @node.dir? ? @node.path : File.dirname(@node.path)
    end
    
    def retrieve_repository_member
      return nil unless current_repository
      return true if current_repository.public?
      return nil unless logged_in?
      current_repository.member?(current_user, repository_path)
    end
    
    def retrieve_repository_admin
      return nil unless current_repository
      return nil unless logged_in? || current_repository.public?
      current_repository.admin?(current_user)
    end
    
    def retrieve_current_user
      authenticate_with_http_basic { |u, p | User.find_by_token(u) } || (session[:user_id] && User.find_by_id(session[:user_id]))
    end

    def repository_subdomain
      request.subdomains.first
    end
  
    def check_for_repository
      if current_repository
        true
      else
        redirect_to install_path
        false
      end
    end
    
    def default_repository
      Repository.find(:first)
    end
    
    def subdomain_repository
      !repository_subdomain.blank? && Repository.find_by_subdomain(repository_subdomain)
    end
end
