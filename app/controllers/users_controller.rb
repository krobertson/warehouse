class UsersController < ApplicationController
  before_filter :login_required, :only   => :update
  before_filter :admin_required, :except => :update
  
  def index
    @users = User.paginate :all, :page => params[:page], :order => 'identity_url'
  end
  
  def update
    if params[:id].blank?
      @sheet = 'profile-form'
      @user  = current_user
    else
      return unless admin_required
      @user  = User.find params[:id]
      @sheet = "profile-#{dom_id @user}"
    end
    @user.attributes = params[:user]
    if params[:id] && params[:user]
      @user.admin = params[:user][:admin] == '1'
    end
    respond_to do |format|
      format.js
    end
  end
  
  def destroy
    @user = User.find params[:id]
    @user.destroy
    respond_to do |format|
      format.js
    end
  end
end
