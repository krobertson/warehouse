class UsersController < ApplicationController
  before_filter :login_required
  
  def update
    if current_user.update_attributes(params[:user])
      redirect_to profile_path
    else
      render :action => 'show'
    end
  end
end
