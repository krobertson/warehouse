class PermissionsController < ApplicationController
  def index
    @permission ||= Permission.new
    @members      = current_repository.permissions.group_by &:user
    render :action => 'index'
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
  
  alias_method :anon, :update
end
