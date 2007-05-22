class PermissionsController < ApplicationController
  def index
    @permission = Permission.new
    @members    = current_repository.permissions.group_by &:user
  end
  
  def create
    if params[:email].blank?
      @permission = current_repository.grant(params[:permission])
    else
      @user = User.find_or_initialize_by_email(params[:email])
      @permission = current_repository.invite(@user, params[:permission])
    end
    if @permission.nil? || @permission.new_record?
      @permission ||= Permission.new
      render :action => 'new'
    else
      flash[:notice] = params[:email].blank? ? "Anonymous permission was created successfully" : "#{params[:email]} was granted access."
      redirect_to permissions_path
    end
  end
end
