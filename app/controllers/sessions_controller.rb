class SessionsController < ApplicationController
  def create
    authenticate_with_open_id do |result, identity_url|
      if result.successful? && @current_user = User.find_or_create_by_identity_url(identity_url)
        session[:user_id] = @current_user.id
        redirect_to root_path
      else
        flash[:error] = result.message || "Sorry, no user by that identity URL exists (#{identity_url})"
        redirect_to new_session_path
      end
    end
  end
  
  def destroy
    reset_session
    redirect_to root_path
  end
end
