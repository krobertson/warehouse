class PermissionsController < ApplicationController
  before_filter :repository_admin_required
  before_filter :load_all_repositories

  def index
    respond_to do |format|
      format.html do
        @permission ||= Permission.new
        @members      = current_repository.permissions.group_by &:user
        render :action => 'index'
      end

      format.text do
        @repositories = repository_subdomain.blank? ? Repository.find(:all) : [current_repository]
        render :action => 'index', :layout => false
      end
    end
  end
  
  def create
    if params[:email].blank?
      @permission = current_repository.grant(params[:permission])
    else
      @user = User.find_or_initialize_by_email(params[:email])
      @permission = current_repository.invite(@user, params[:permission])
    end
    if @permission.nil? || @permission.new_record?
      if (@user && @user.errors.any?) || (@permission && @permission.errors.any?)
        @permission ||= Permission.new
        render :action => 'new'
      else
        flash.now[:error] = "No permissions were created."
        index
      end
    else
      flash.now[:notice] = params[:email].blank? ? "Anonymous permission was created successfully" : "#{params[:email]} was granted access."
      index
    end
  end
  
  def update
    @user = params[:user_id].blank? ? nil : User.find(params[:user_id])
    current_repository.permissions.set(@user, params[:permission])
    flash[:notice] = "Permissions updated"
    redirect_to permissions_path
  end
    
  def anon
    case request.method
      when :put    then update
      when :delete then destroy
    end
  end
  
  def destroy
    params[:user_id] ? destroy_user_permissions : destroy_single_permission
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
    
    def destroy_single_permission
      @permission = current_repository.permissions.find(params[:id])
      @permission.update_attribute :active, false
      flash[:notice] = "Read-#{'write' if @permission.full_access?} access for #{@permission.path} has been removed for #{@permission.login}."
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
        repository_admin? || access_denied(:error => "You must be an administrator for this repository to visit this page.")
      end
    end
end
