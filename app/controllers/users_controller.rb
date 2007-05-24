class UsersController < ApplicationController
  before_filter :profile_required
  before_filter :find_user, :except => :index
  
  def index
    @users = User.find(:all, :include => :permissions)
  end
  
  def update
    if @user.update_attributes(params[:user])
      redirect_to(@user != current_user ? user_path(@user) : profile_path)
    else
      render :action => 'show'
    end
  end
  
  protected
    def profile_required
      logged_in? && (params[:id].nil? || (params[:id] == current_user.id.to_s)) || access_denied(:error => "You can only access your own profile.")
    end

    def find_user
      @user = current_user
    end
end
