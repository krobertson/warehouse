class PermissionsController < ApplicationController
  skip_before_filter :check_for_repository
  before_filter :check_for_repository
  before_filter :repository_admin_required
  before_filter :load_all_repositories

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
      current_repository.rebuild_permissions
      flash.now[:notice] = params[:email].blank? ? "Anonymous permission was created successfully" : "#{params[:email]} was granted access."
      index
    end
  end
  
  def update
    @user = params[:user_id].blank? ? nil : User.find(params[:user_id])
    current_repository.permissions.set(@user, params[:permission])
    current_repository.rebuild_permissions
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
    current_repository.rebuild_permissions
  end
  
  protected
    def load_all_repositories
      @repositories = Repository.find(:all, :conditions => ['id != ?', current_repository.id]) if admin?
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

    # slight tweak that checks basic auth too
    def repository_admin_required
      if request.format.text?
        @current_user = authenticate_or_request_with_http_basic { |u, p| user = User.find_by_token(u); repository_admin? && user } unless logged_in?
        return false if performed?
      else
        repository_admin? || status_message(:error, "You must be an administrator for this repository to visit this page.")
      end
    end
end
