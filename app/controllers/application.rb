class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  helper_method :current_repository, :logged_in?, :current_user, :admin?, :controller_path, :repository_admin?, :repository_member?, :repository_subdomain, :hosted_url
  
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
      repository_member? || access_denied_message("You must be a member of this repository to visit this page.")
    end
    
    # specifies a controller action where a repository admin is required.
    def repository_admin_required
      repository_admin? || access_denied_message("You must be an administrator for this repository to visit this page.")
    end
    
    # specifies a controller action that only warehouse administrators are allowed
    def admin_required
      admin? || access_denied_message("You must be an administrator to visit this page.")
    end

    def login_required
      logged_in? || access_denied_message("You must be logged in to edit a profile.")
    end

    # handles non-html responses in DEV mode when there are exceptions
    def rescue_action_locally(exception)
      if api_format?
        render :text => "Error: #{exception.message}", :status => :internal_server_error
      else
        super
      end
    end

    # handles non-html responses in PRODUCTION mode when there are exceptions
    def rescue_action_in_public(exception)
      if api_format?
        render :text => "An error has occurred with Warehouse.  Check your #{RAILS_ENV} logs.", :status => :internal_server_error
      else
        super
      end
    end

    # Renders simple page w/ the error message.
    def status_message(type, message = nil, template = nil)
      @message = message || "A login is required to visit this page."
      if api_format?
        render :text => @message, :status => :internal_server_error
      else
        render :template => (template || "shared/#{type}")
      end
      false
    end

    # Same as #status_message but sends the 401 basic auth headers
    def access_denied_message(message)
      if api_format?
        headers["WWW-Authenticate"] = %(Basic realm="Web Password")
        render :text => "Couldn't authenticate you.", :status => :unauthorized
      else
        status_message(:error, message)
      end
    end

    def node_directory_path
      return nil if @node.nil?
      @node.dir? ? @node.path : File.dirname(@node.path)
    end
    
    def retrieve_repository_member
      return true if admin?
      return nil unless current_repository
      return true if current_repository.public?
      return nil unless logged_in?
      current_repository.member?(current_user, node_directory_path)
    end
    
    def retrieve_repository_admin
      return true if admin?
      return nil unless current_repository
      return nil unless current_repository.public? || logged_in?
      current_repository.admin?(current_user)
    end
    
    def current_user=(value)
      session[:user_id] = value ? value.id : nil
      @current_user     = value
    end
    
    def retrieve_current_user
      @current_user || 
        authenticate_with_http_basic { |u, p| User.find_by_token(u) } ||
        (cookies[:login_token] && User.find_by_id_and_token(*cookies[:login_token].split(";"))) || 
        (session[:user_id] && User.find_by_id(session[:user_id]))
    end
    
    def retrieve_current_repository
      repository_subdomain.blank? ? nil : Repository.find_by_subdomain(repository_subdomain)
    end
  
    def check_for_repository
      return true if current_repository
      if !Warehouse.domain.blank? && Repository.count > 0
        redirect_to(logged_in? ? root_changesets_path : root_public_changesets_path)
      else
        reset_session
        redirect_to installer_path
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

  if USE_REPO_PATHS
    def repository_subdomain
      params[:repo]
    end

    def hosted_url(*args)
      repository, name = extract_repository_and_args(args)
      repository ||= current_repository
      returning send("#{name}_path", *args) do |path|
        if repository && name !~ REPO_ROOT_REGEX
          path.insert 0, "/#{repository.subdomain}"
        end
      end
    end
  else
    def repository_subdomain
      request.host.gsub %r(\.?#{Regexp.escape(Warehouse.domain)}), ''
    end

    def hosted_url(*args)
      repository, name = extract_repository_and_args(args)
      if repository.nil?
        send("#{name}_path", *args)
      else
        "http%s://%s%s%s" % [
          ('s' if request.ssl?),
          (repository ? repository.domain : Warehouse.domain),
          (':' + request.port.to_s unless request.port == request.standard_port),
          send("#{name}_path", *args)
          ]
        end
    end
  end
    
    def extract_repository_and_args(args)
      if args.first.is_a?(Symbol)
        [nil, args.shift]
      else
        [args.shift, args.shift]
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
    
    def api_format?
      request.format.atom? || request.format.xml?
    end
end
