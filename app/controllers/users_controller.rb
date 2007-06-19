class UsersController < ApplicationController
  before_filter :login_required
  
  def update
    respond_to do |format|
      if current_user.update_attributes(params[:user])
        format.html { redirect_to profile_path }
        format.js
      else
        format.html { render :action => 'show' }
        format.js
      end
    end
  end
end
