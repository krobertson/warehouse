class PermissionsController < ApplicationController
  skip_before_filter :check_for_repository
  before_filter :check_for_repository, :except => :index
  before_filter :check_for_repository_or_show_repos, :only => :index
  before_filter :repository_admin_required
  before_filter :load_all_repositories, :only => [:index, :create]

  def index
    @permission ||= Permission.new
    @invitees     = User.find(:all, :order => 'login, email')
    @members      = current_repository.permissions.group_by &:user
    @invitees.delete_if { |i| @members.keys.include?(i) }
    render :action => 'index'
  end
  
  def create
    @permission = current_repository.grant(params[:permission])
    if @permission.nil? || @permission.new_record?
      if (@user && @user.errors.any?) || (@permission && @permission.errors.any?)
        @permission ||= Permission.new
        render :action => 'new'
      else
        flash.now[:error] = "No permissions were created."
        index
      end
    else
      after_permission_update
      flash.now[:notice] = params[:email].blank? ? "Anonymous permission was created successfully" : "#{params[:email]} was granted access."
      index
    end
  end
  
  def update
    @user = params[:user_id].blank? ? nil : User.find(params[:user_id])
    current_repository.permissions.set(@user, params[:permission])
    after_permission_update
    flash[:notice] = "Permissions updated"
    redirect_to permissions_path
  end
    
  def anon
    case request.method
      when :put    then update
      when :delete then destroy(:anon)
    end
  end
  
  def destroy(anon = false)
    if params[:user_id]
      destroy_user_permissions
    elsif anon
      destroy_anon_permissions
    else
      destroy_single_permission
    end
    after_permission_update
  end
  
  protected
    def load_all_repositories
      @repositories = (admin? ? Repository : current_user.administered_repositories).find(:all, :conditions => ['repositories.id != ?', current_repository.id])
    end
    
    def destroy_user_permissions
      @user = User.find(params[:user_id])
      Permission.transaction do
        @user.permissions.for_repository(current_repository).each { |p| p.update_attribute :active, false }
      end
      flash[:notice] = "#{@user.name} has been removed from this repository."
      render :update do |page|
        page[@user].hide
      end
    end
    
    def destroy_anon_permissions
      Permission.transaction do
        current_repository.permissions.find_all_by_user_id(nil).each { |p| p.update_attribute :active, false }
      end
      flash[:notice] = "Anonymous access has been removed for this repository."
      render :update do |page|
        page[:user_anon].hide
      end
    end
    
    def destroy_single_permission
      @permission = current_repository.permissions.find params[:id]
      @permission.update_attribute :active, false
      flash[:notice] = "Read-#{'write' if @permission.full_access?} access for #{@permission.path} has been removed for #{@permission.user_id ? @permission.user.name : "Anonymous"}."
      render :update do |page|
        page[@permission].hide
      end
    end

    def check_for_repository_or_show_repos
      check_for_valid_domain
      return false if performed?
      return true if current_repository
      if logged_in? && repository_subdomain.blank?
        @repositories = admin? ? Repository.find(:all) : current_user.administered_repositories
        render :template => 'shared/administered'
      elsif !Warehouse.domain.blank? && Repository.count > 0
        redirect_to(logged_in? ? hosted_url(:changesets) : hosted_url(:public_changesets))
      else
        reset_session
        redirect_to installer_path
      end
      false
    end
    
    def after_permission_update
      current_repository.rebuild_permissions
      cache_path = File.join(RAILS_ROOT, 'tmp', 'cache', current_repository.domain)
      cache_path << ".#{request.port}" unless request.port == 80
      rm_rf cache_path if File.exist?(cache_path)
    end
end
