class ChangesetsController < ApplicationController
  before_filter :check_for_changeset_rev, :only => :index
  before_filter :repository_subdomain_or_login_required, :only => :index
  before_filter :repository_member_required, :except => [:index, :public]
  before_filter :root_domain_required, :only => :public
  before_filter :find_node, :only => :diff

  caches_action_content :index, :show, :public
  
  helper_method :previous_changeset, :next_changeset
  expiring_attr_reader :changeset_paths, :find_changeset_paths

  def index
    return global_index if repository_subdomain.blank? && logged_in?

    @changesets = case changeset_paths
      when :all then current_repository.changesets.search(params[:q], :page => params[:page], :order => 'changesets.changed_at desc')
      when []   then []
      else current_repository.changesets.search_by_paths(params[:q], changeset_paths, :page => params[:page], :order => 'changesets.changed_at desc')
    end
    respond_for_changesets
  end

  def public
    @repositories = Repository.find_all_by_public(true)
    @changesets   = @repositories.empty? ? [] :
      Changeset.paginate(:conditions => ['repository_id in (?)', @repositories.collect(&:id)], :page => params[:page], :order => 'changesets.changed_at desc')
    respond_for_changesets
  end
  
  def global_index
    @repositories = current_user.repositories
    @changesets   = Changeset.paginate_by_paths(current_user.repositories.paths, :page => params[:page], :order => 'changesets.changed_at desc')
    respond_for_changesets
  end
  
  def show
    @changeset = current_repository.changesets.find_by_paths(changeset_paths, :conditions => ['revision = ?', params[:id]])
    unless @changeset
      return status_message(:error, "You must be a member of this repository to visit this page.", "changesets/error")
    end
    @changes = @changeset.changes.paginate(:page => params[:page])
    respond_to do |format|
      format.html
      format.diff { render :action => 'show', :layout => false }
    end
  end

  def action_url_to_id
    super + 
      if (action_name == 'index' && repository_subdomain.blank? && logged_in?) || (action_name != 'public' && changeset_paths != :all)
        "_user_#{current_user.id}"
      else
        ''
      end
  end

  def action_caching_layout
    !(api_format? || request.format.diff?)
  end

  protected
    %w(previous_changeset next_changeset changeset_paths).each { |m| expiring_attr_reader m, "find_#{m}" }
    
    def find_previous_changeset
      current_repository.changesets.find_by_paths(changeset_paths, :conditions => ['changed_at < ?', @changeset.changed_at], :order => 'changed_at desc')
    end
    
    def find_next_changeset
      current_repository.changesets.find_by_paths(changeset_paths, :conditions => ['changed_at > ?', @changeset.changed_at], :order => 'changed_at')
    end
    
    def find_changeset_paths
      if current_repository.public? || admin? || repository_admin?
        :all
      else
        (logged_in? && current_user.permissions.paths_for(current_repository)) || []
      end
    end

    def respond_for_changesets
      respond_to do |format|
        format.html do
          @users = User.find_all_by_logins(@changesets.collect(&:author).uniq).index_by(&:login)
          render :action => 'index'
        end
        format.atom do
          render :layout => false, :action => 'index'
        end
      end
    end

    def repository_subdomain_or_login_required
      if repository_subdomain.blank? 
        if logged_in?
          true
        else
          redirect_to root_public_changesets_path
          false
        end
      else
        repository_member_required
      end
    end

    def root_domain_required
      if repository_subdomain.blank?
        true
      else
        redirect_to hosted_url(:changesets)
        false
      end
    end

    @@global_actions = %w(index public)
    def check_for_repository
      return true if installed? && repository_subdomain.blank? && @@global_actions.include?(action_name)
      super
    end
    
    def check_for_changeset_rev
      return unless params[:rev]
      if num = params[:rev].scan(/\d+/).first
        redirect_to hosted_url(:changeset, num)
      else
        flash[:notice] = "Bad ?rev parameter: #{params[:rev].inspect}"
        redirect_to hosted_url(:changesets)
      end
    end

    def find_node
      case params[:r]
        when 'numb'
          params[:r] = params[:n].to_i
        when 'date'
          params[:r] = Date.new(params[:date][:year].to_i, params[:date][:month].to_i, params[:date][:day].to_i)
        when nil
          params[:r] = 'h'
      end
      @revision = params[:rev][1..-1].to_i if params[:rev]
      @node     = current_repository.node(params[:paths] * '/', @revision)
    end
end
