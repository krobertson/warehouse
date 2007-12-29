class UsersController < ApplicationController
  skip_before_filter :check_for_repository
  before_filter :login_required, :only   => :update
  before_filter :admin_required, :except => :update
  before_filter :strip_admin_value
  
  def index
    @users = User.paginate :all, :page => params[:page], :order => 'identity_url'
  end
  
  def create
    @user = User.new(params[:user])
    @user.admin = @is_admin
    
    render :update do |page|
      if @user.save
        UserMailer.deliver_invitation(current_user, @user)
        Repository.rebuild_htpasswd_for(@user)
        page.redirect_to hosted_url(:users)
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
    @user.admin = @is_admin if admin? && params[:id] && params[:user]
    @user.save
    CacheKey.sweep_cache
    Repository.rebuild_htpasswd_for(@user)
    redirect_to(params[:to] || root_path)
  end
  
  def destroy
    @user = User.find params[:id]
    @user.destroy
    CacheKey.sweep_cache
    Repository.rebuild_htpasswd_for(@user)
    respond_to do |format|
      format.js
    end
  end

protected
  def strip_admin_value
    params[:user] ||= {}
    @is_admin = params[:user].delete(:admin) == '1'
  end
end
