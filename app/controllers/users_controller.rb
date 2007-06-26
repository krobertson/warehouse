class UsersController < ApplicationController
  skip_before_filter :check_for_repository
  before_filter :login_required, :only   => :update
  before_filter :admin_required, :except => :update
  
  def index
    @users = User.paginate :all, :page => params[:page], :order => 'identity_url'
  end
  
  def create
    @user = User.new(params[:user])
    if params[:user]
      @user.admin = params[:user][:admin] == '1'
    end
    
    render :update do |page|
      if @user.save
        UserMailer.deliver_invitation(current_user, @user)
        current_repository.rebuild_htpasswd_for(@user)
        page.redirect_to users_path
      else
        page["error-#{dom_id @user}"].show.replace_html(error_messages_for(:user))
      end
    end
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
    @user.save
    Repository.rebuild_htpasswd_for(@user)
    redirect_to(params[:to] || root_path)
  end
  
  def destroy
    @user = User.find params[:id]
    @user.destroy
    current_repository.rebuild_htpasswd_for(@user)
    respond_to do |format|
      format.js
    end
  end
end
