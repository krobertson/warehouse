class UsersController < ApplicationController
  before_filter :find_user, :except => :index
  
  def update
    if @user.update_attributes(params[:user])
      redirect_to(@user != current_user ? user_path(@user) : profile_path)
    else
      render :action => 'show'
    end
  end
  
  protected
    def find_user
      @user = params[:id] ? User.find(params[:id]) : current_user
    end
end
