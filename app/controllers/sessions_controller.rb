class SessionsController < ApplicationController
  skip_before_filter :check_for_repository
  def create
    authenticate_with_open_id do |result, identity_url|
      if result.successful? && self.current_user = User.find_or_create_by_identity_url(identity_url)
        redirect_to root_path
      else
        access_denied :error => result.message || "Sorry, no user by that identity URL exists (#{identity_url})"
      end
    end
  end
  
  def destroy
    reset_session
    redirect_to root_path
  end
  
  def forget
    if !params[:email].blank? && @user = User.find_by_email(params[:email].downcase)
      @user.reset_token!
      access_denied :error => "Email sent to #{params[:email]}."
    else
      access_denied :error => "No user found for #{params[:email]}."
    end
  end
  
  def reset
    if params[:token].blank? && !logged_in?
      access_denied :error => "Invalid token for resetting your Open ID Identity"
      return
    end
    
    self.current_user = User.find_by_token(params[:token]) unless params[:token].blank?
    return if request.get? && params[:open_id_complete].nil?
    authenticate_with_open_id do |result, identity_url|
      if result.successful?
        current_user.update_attribute :identity_url, identity_url
        session[:user_id] = current_user.id
        redirect_to profile_path
      else
        access_denied :error => result.message || "There were problems logging in with Open ID."
      end
    end
  end
end
