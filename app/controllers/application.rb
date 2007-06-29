# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  helper_method :current_repository, :logged_in?, :current_user, :admin?, :controller_path, :repository_admin?, :repository_member?, :repository_subdomain
  
  session(Warehouse.session_options) unless Warehouse.domain.blank?
  
  around_filter :set_context
  
  before_filter :check_for_valid_domain
  before_filter :check_for_repository

  expiring_attr_reader :current_user,       :retrieve_current_user
  expiring_attr_reader :repository_member?, :retrieve_repository_member
  expiring_attr_reader :repository_admin?,  :retrieve_repository_admin
  expiring_attr_reader :current_repository, :retrieve_current_repository
  expiring_attr_reader :admin?,             :retrieve_admin

  def logged_in?
    !!current_user
  end
  
  def admin?
    logged_in? && current_user.admin?
  end
  
  protected
    def repository_member_required
      repository_member? || status_message(:error, "You must be a member of this repository to visit this page.")
    end
    
    # specifies a controller action where a repository admin is required.
    def repository_admin_required
      repository_admin? || status_message(:error, "You must be an administrator for this repository to visit this page.")
    end
    
    # specifies a controller action that only warehouse administrators are allowed
    def admin_required
      admin? || status_message(:error, "You must be an administrator to visit this page.")
    end

    def login_required
      logged_in? || status_message(:error, "You must be logged in to edit a profile.")
    end

    def status_message(type, message = nil, template = nil)
      @message = message || "A login is required to visit this page."
      render :template => (template || "shared/#{type}")
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
    
    def current_user=(value)
      session[:user_id] = value ? value.id : nil
      @current_user     = value
    end
    
    def retrieve_current_user
      @current_user || authenticate_with_http_basic { |u, p | User.find_by_token(u) } || (session[:user_id] && User.find_by_id(session[:user_id]))
    end
    
    def retrieve_current_repository
      repository_subdomain.blank? ? nil : Repository.find_by_subdomain(repository_subdomain)
    end

    def repository_subdomain
      request.host.gsub %r(\.?#{Regexp.escape(Warehouse.domain)}), ''
    end
  
    def check_for_repository
      return true if current_repository
      if Repository.count > 0
        redirect_to(logged_in? ? changesets_path : public_changesets_path)
      else
        reset_session
        redirect_to install_path
      end
      false
    end
    
    def check_for_valid_domain
      if (Warehouse.domain.blank? && Repository.count > 0) || (!Warehouse.domain.blank? && request.host != Warehouse.domain && request.host.gsub(/^[\w-]+\./, '') != Warehouse.domain)
        status_message :error, "Invalid domain '#{request.host}'.", 'shared/domain'
      else
        true
      end
    end

    # stores cache fragments that have already been read by
    # #cached_in?
    def current_cache
      @cache ||= {}
    end
    
    # checks if the given name has been cached.  If so,
    # read into #current_cache
    def cached_in?(name, options = nil)
      name && current_cache[name] ||= read_fragment(name, options)
    end

    def set_context
      ActiveRecord::Base.with_context do
        yield
      end
    end
end
