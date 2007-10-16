class SessionsController < ApplicationController
  skip_before_filter :check_for_repository

  def create
    if using_open_id?
      cookies['use_svn'] = {:value => '0', :expires => 1.year.ago.utc, :domain => ".#{Warehouse.domain}", :path => '/'}
      authenticate_with_open_id do |result, identity_url|
        if result.successful? && self.current_user = User.find_or_create_by_identity_url(identity_url)
          successful_login
        else
          status_message :error, result.message || "Sorry, no user by that identity URL exists (#{identity_url})"
        end
      end
    else
      cookies['use_svn'] = {:value => '1', :expires => 1.year.from_now.utc, :domain => ".#{Warehouse.domain}", :path => '/'}
      if self.current_user = User.authenticate(params[:login], params[:password])
        successful_login
      else
        status_message :error, "Invalid Password"
      end
    end
  end
  
  def destroy
    reset_session
    cookies[:login_token] = {:value => '', :expires => 1.year.ago, :domain => ".#{Warehouse.domain}", :path => '/'}
    redirect_to root_path
  end
  
  def forget
    if !params[:email].blank? && @user = User.find_by_email(params[:email].downcase)
      @user.reset_token!
      UserMailer.deliver_forgot_password(@user)
      status_message :info, "Email sent to #{params[:email]}."
    else
      status_message :error, "No user found for #{params[:email]}."
    end
  end
  
  def reset
    if params[:token].blank? && !logged_in?
      status_message :error, "Invalid token for resetting your Open ID Identity"
      return
    end
    
    self.current_user = User.find_by_token(params[:token]) unless params[:token].blank?
    return if request.get? && params[:open_id_complete].nil?
    if using_open_id?
      cookies['use_svn'] = {:value => '0', :expires => 1.year.ago.utc, :domain => ".#{Warehouse.domain}", :path => '/'}
      authenticate_with_open_id do |result, identity_url|
        if result.successful?
          current_user.identity_url = identity_url
        else
          status_message :error, result.message || "There were problems logging in with Open ID."
        end
      end
    else
      cookies['use_svn'] = {:value => '1', :expires => 1.year.from_now.utc, :domain => ".#{Warehouse.domain}", :path => '/'}
    end
    unless performed? 
      current_user.reset_token!
      redirect_to root_path
    end
  end

protected
  def successful_login
    cookies[:login_token] = {:value => "#{current_user.id};#{current_user.token}", :expires => 1.year.from_now.utc, :domain => ".#{Warehouse.domain}", :path => '/'}
    redirect_to root_path
  end
end
