class MembersController < ApplicationController
  def index
    @user = User.new
  end
  
  def create
    @user = User.find_or_initialize_by_email(params[:email])
    unless current_repository.invite(@user, :login => params[:login], :admin => params[:admin])
      render :action => 'new'
      return
    end
    flash[:notice] = "The member at #{params[:email]} was invited successfully."
    redirect_to members_path
  end
end
